class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  before_action :log_request_info

  private

  def log_request_info
    # Rails.logger.info "Processing #{controller_name}##{action_name}"
    # Rails.logger.info "Request ID: #{request.request_id}"
    # Rails.logger.info "User Agent: #{request.user_agent}"
    # Rails.logger.info "Parameters: #{params.except(:controller, :action).inspect}"
  end
end
