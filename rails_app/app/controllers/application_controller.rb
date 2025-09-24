require 'net/http'
require 'uri'

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
end
