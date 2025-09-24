require 'net/http'
require 'json'
require 'uri'

class MinecraftApiService
  BASE_URL = 'https://minecraft.fandom.com/es/api.php'
  IMAGE_BASE_URL = 'https://minecraft.fandom.com/es/wiki/Special:FilePath/'
  
  def self.get_mob_info(mob_name)
    begin
      # Construct API URL for mob information
      params = {
        action: 'query',
        titles: mob_name,
        prop: 'extracts|images',
        format: 'json',
        exintro: true,
        explaintext: true,
        exsectionformat: 'plain'
      }
      
      url = build_url(BASE_URL, params)
      response = make_request(url)
      
      if response.is_a?(Net::HTTPSuccess)
        data = JSON.parse(response.body)
        parse_mob_data(data, mob_name)
      else
        default_mob_info(mob_name)
      end
    rescue => e
      Rails.logger.error "MinecraftApiService error: #{e.message}"
      default_mob_info(mob_name)
    end
  end
  
  private
  
  def self.build_url(base_url, params)
    uri = URI(base_url)
    uri.query = URI.encode_www_form(params)
    uri.to_s
  end
  
  def self.make_request(url)
    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    
    request = Net::HTTP::Get.new(uri)
    request['User-Agent'] = 'RailsDebuggingApp/1.0'
    
    http.request(request)
  end
  
  def self.parse_mob_data(data, mob_name)
    pages = data.dig('query', 'pages')
    return default_mob_info(mob_name) unless pages
    
    page_data = pages.values.first
    return default_mob_info(mob_name) unless page_data
    
    {
      title: page_data['title'] || mob_name,
      extract: clean_extract(page_data['extract']),
      images: parse_images(page_data['images'] || []),
      found: page_data['extract'].present?
    }
  end
  
  def self.clean_extract(extract)
    return "No description available." unless extract.present?
    
    # Clean HTML entities and limit length
    cleaned = extract.gsub(/\\u003C[^>]*\\u003E/, '') # Remove HTML tags
                    .gsub(/\\u003C/, '<')
                    .gsub(/\\u003E/, '>')
                    .gsub(/<[^>]*>/, '') # Remove any remaining HTML
                    .strip
    
    # Limit to first 500 characters and add ellipsis if needed
    if cleaned.length > 500
      cleaned[0..497] + "..."
    else
      cleaned
    end
  end
  
  def self.parse_images(images_data)
    return [] unless images_data.is_a?(Array)
    
    # Filter and format image URLs
    images_data.select { |img| img['title'] && img['title'].match?(/\.(png|jpg|jpeg|gif|webp)$/i) }
               .first(5) # Limit to first 5 images
               .map do |img|
                 filename = img['title'].gsub('Archivo:', '').gsub('File:', '').gsub(' ', '_')
                 original_url = "#{IMAGE_BASE_URL}#{URI.encode_www_form_component(filename)}"
                 
                 # Get the real image URL by following redirects
                 real_url = get_real_image_url(original_url) || original_url
                 
                 # Debug logging
                 Rails.logger.info "Image processing: #{filename}"
                 Rails.logger.info "  Original: #{original_url}"
                 Rails.logger.info "  Real URL: #{real_url}"
                 
                 {
                   title: filename,
                   url: real_url,
                   original_url: original_url,
                   proxy_url: "/image_proxy?url=#{URI.encode_www_form_component(original_url)}"
                 }
               end
  end
  
  def self.get_real_image_url(url)
    begin
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http.read_timeout = 10 # Add timeout
      
      request = Net::HTTP::Get.new(uri)
      request['User-Agent'] = 'Mozilla/5.0 (compatible; RailsDebuggingApp/1.0)'
      request['Accept'] = 'image/*'
      
      # Follow up to 3 redirects
      3.times do
        response = http.request(request)
        
        case response
        when Net::HTTPRedirection
          location = response['location']
          if location
            # Handle relative redirects
            if location.start_with?('/')
              location = "#{uri.scheme}://#{uri.host}#{location}"
            end
            uri = URI(location)
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = (uri.scheme == 'https')
            http.verify_mode = OpenSSL::SSL::VERIFY_PEER
            http.read_timeout = 10
            request = Net::HTTP::Get.new(uri)
            request['User-Agent'] = 'Mozilla/5.0 (compatible; RailsDebuggingApp/1.0)'
            request['Accept'] = 'image/*'
          else
            break
          end
        when Net::HTTPSuccess
          return uri.to_s # Return the final URL
        else
          break
        end
      end
      
      nil
    rescue => e
      Rails.logger.error "Error getting real image URL for #{url}: #{e.message}"
      nil
    end
  end
  
  def self.default_mob_info(mob_name)
    {
      title: mob_name,
      extract: "This is a Minecraft mob. No additional information available from the wiki.",
      images: [],
      found: false
    }
  end
end
