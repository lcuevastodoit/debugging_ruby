class LogMonitorService
  include Concurrent::Async

  def initialize
    @monitoring = false
    @futures = []
    @log_locations = Settings.debugging_game.log_locations.to_h
  end

  def start_monitoring
    return if @monitoring
    
    @monitoring = true
    @futures = []
    
    @log_locations.each do |tool, location|
      expanded_path = File.expand_path(location)
      
      unless File.exist?(expanded_path)
        Rails.logger.warn "Log file not found: #{expanded_path}"
        next
      end
      
      # Use lighter monitoring with background job processing
      future = Concurrent::Future.execute do
        monitor_log_file_lightweight(expanded_path, tool.to_s)
      end
      
      @futures << future
    end
    
    # Schedule periodic leaderboard updates
    schedule_periodic_jobs
    
    Rails.logger.info "Started monitoring #{@futures.length} log files with background processing"
  end

  def stop_monitoring
    @monitoring = false
    @futures.each(&:cancel)
    @futures.clear
    Rails.logger.info "Stopped log monitoring"
  end

  def monitoring?
    @monitoring
  end

  private

  def monitor_log_file_async(tool, file_path)
    Concurrent::Future.execute do
      monitor_log_file(tool, file_path)
    end
  end

  def monitor_log_file(tool, file_path)
    last_position = File.size(file_path)
    
    loop do
      break unless @monitoring
      
      begin
        current_size = File.size(file_path)
        
        if current_size > last_position
          new_content = read_new_content(file_path, last_position, current_size)
          process_new_commands(tool, new_content) if new_content.present?
          last_position = current_size
        end
        
        sleep 0.5 # Check every 500ms
      rescue => e
        Rails.logger.error "Error monitoring #{tool} log: #{e.message}"
        sleep 5 # Wait longer on error
      end
    end
  end

  def read_new_content(file_path, start_pos, end_pos)
    return nil if start_pos >= end_pos
    
    File.open(file_path, 'r') do |file|
      file.seek(start_pos)
      file.read(end_pos - start_pos)
    end
  rescue => e
    Rails.logger.error "Error reading file content: #{e.message}"
    nil
  end

  def process_new_commands(tool, content)
    # Use background job for heavy processing instead of inline processing
    LogProcessingJob.perform_later(content, tool.to_s)
  end

  def schedule_periodic_jobs
    # Schedule leaderboard updates every 5 minutes
    LeaderboardUpdateJob.set(wait: 5.minutes).perform_later
    
    Rails.logger.info "Scheduled periodic background jobs"
  end

  def extract_commands(content)
    # Extract meaningful commands from log content
    # This will vary based on the tool's log format
    lines = content.split("\n").map(&:strip).reject(&:blank?)
    
    # Filter out timestamps, prompts, and other noise
    commands = lines.select do |line|
      # Skip empty lines, timestamps, and common prompt patterns
      next false if line.empty?
      next false if line.match?(/^\d{4}-\d{2}-\d{2}/) # timestamps
      next false if line.match?(/^irb\(\w+\):/) # IRB prompts
      next false if line.match?(/^pry\(\w+\)>/) # Pry prompts
      next false if line.match?(/^\[?\d+\]?[\s>]*$/) # simple prompts
      next false if line.match?(/^=> /) # output lines
      
      true
    end
    
    # Clean up commands
    commands.map do |cmd|
      # Remove common prefixes and suffixes
      cmd.gsub(/^[\[\d\]>\s]*/, '') # Remove prompt prefixes
         .gsub(/\s*#.*$/, '') # Remove comments
         .strip
    end.reject(&:blank?)
  end
end
