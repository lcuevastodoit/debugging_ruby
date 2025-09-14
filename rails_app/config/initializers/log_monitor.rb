# Start the LogMonitorService automatically when Rails starts
Rails.application.config.after_initialize do
  # Check if we're in a server process (not in rake tasks, console, etc)
  if defined?(Rails::Server) || Rails.const_defined?('Console') || $0.include?('puma') || ENV['SOLID_QUEUE_WORKER']
    Rails.logger.info "🔍 Initializing LogMonitorService..."

    begin
      LogMonitorService.new.start_monitoring
      Rails.logger.info "✅ LogMonitorService started successfully"
    rescue => e
      Rails.logger.error "❌ Failed to start LogMonitorService: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
  end
end
