class TestJob < ApplicationJob
  queue_as :default

  def perform(message = "Hello from Solid Queue!")
    Rails.logger.info "🎯 TestJob executed: #{message}"
    
    # Simulate some work
    sleep(2)
    
    Rails.logger.info "✅ TestJob completed successfully"
    puts "TestJob finished: #{message}"
  end
end
