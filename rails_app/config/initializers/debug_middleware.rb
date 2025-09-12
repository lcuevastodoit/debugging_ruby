class DebugMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)
    start_time = Time.current

    # Rails.logger.info "[DEBUG MIDDLEWARE] Starting request: #{request.request_method} #{request.path}"
    # Rails.logger.info "[DEBUG MIDDLEWARE] Request ID: #{request.env['action_dispatch.request_id']}"

    response = @app.call(env)

    end_time = Time.current
    duration = (end_time - start_time) * 1000

    # Rails.logger.info "[DEBUG MIDDLEWARE] Request completed in #{duration.round(2)}ms"
    # Rails.logger.info "[DEBUG MIDDLEWARE] Response status: #{response[0]}"

    # Log slow requests
    if duration > 500
      Rails.logger.warn "[DEBUG MIDDLEWARE] SLOW REQUEST detected: #{duration.round(2)}ms for #{request.path}"
    end

    response
  end
end

if Rails.env.development?
  Rails.application.config.middleware.insert_before 0, DebugMiddleware
end
