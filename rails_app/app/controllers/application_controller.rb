require 'net/http'
require 'uri'
require 'digest'

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  def image_proxy
    url = params[:url]
    return head :bad_request unless url.present?

    # Security: only allow minecraft wiki images
    unless url.match?(/^https:\/\/(minecraft\.fandom\.com|static\.wikia\.nocookie\.net)/)
      return head :forbidden
    end

    # Generate a filename based on the URL
    filename = generate_cached_filename(url)
    cached_path = Rails.root.join('public', 'cached_images', filename)

    # Check if image exists in cache
    if File.exist?(cached_path)
      Rails.logger.info "Serving cached image: #{filename}"
      return send_file cached_path, disposition: 'inline'
    end

    # If not cached, download and cache the image
    begin
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http.read_timeout = 15

      # Follow redirects up to 5 times
      5.times do
        request = Net::HTTP::Get.new(uri)
        request['User-Agent'] = 'Mozilla/5.0 (compatible; RailsDebuggingApp/1.0)'
        request['Accept'] = 'image/*'

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
            http.read_timeout = 15
          else
            return head :not_found
          end
        when Net::HTTPSuccess
          # Save image to cache
          save_to_cache(cached_path, response.body)

          # Send the image data with proper content type
          send_data response.body,
                    type: response.content_type || 'image/png',
                    disposition: 'inline'
          return
        else
          return head :not_found
        end
      end

      head :not_found
    rescue => e
      Rails.logger.error "Image proxy error: #{e.message}"
      head :internal_server_error
    end
  end

  private

  def generate_cached_filename(url)
    # Extract original filename if possible, otherwise use hash
    uri = URI(url)
    original_name = File.basename(uri.path)

    if original_name.present? && original_name.include?('.')
      # Use original filename with hash prefix to avoid conflicts
      hash_prefix = Digest::MD5.hexdigest(url)[0..7]
      "#{hash_prefix}_#{original_name}"
    else
      # Fallback to hash-based filename
      "#{Digest::MD5.hexdigest(url)}.png"
    end
  end

  def save_to_cache(file_path, content)
    # Ensure the cached_images directory exists
    FileUtils.mkdir_p(File.dirname(file_path))

    # Write the file
    File.open(file_path, 'wb') do |file|
      file.write(content)
    end

    Rails.logger.info "Cached image saved: #{File.basename(file_path)}"
  rescue => e
    Rails.logger.error "Failed to cache image: #{e.message}"
  end
end
