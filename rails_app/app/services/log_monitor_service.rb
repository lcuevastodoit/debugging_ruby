class LogMonitorService
  include Concurrent::Async

  def initialize
    @monitoring = false
    @futures = []
    @log_locations = Settings.debugging_game.log_locations.to_h
  end

  # Limpia todos los datos: logs, progreso de usuarios y leaderboard
  def reset_all_data
    reset_log_files
    reset_user_progress
    reset_leaderboard
    Rails.logger.info "✅ All data has been reset successfully"
  end

  def start_monitoring
    return if @monitoring

    # Resetear todos los datos al iniciar el monitoreo
    reset_all_data

    @monitoring = true
    @futures = []

    @log_locations.each do |tool, location|
      expanded_path = File.expand_path(location)

      unless File.exist?(expanded_path)
        Rails.logger.warn "Log file not found: #{expanded_path}"
        next
      end

      # Monitorea usando tail -f y lee stdout en tiempo real
      future = Concurrent::Future.execute do
        monitor_log_file_tail(tool.to_s, expanded_path)
      end

      @futures << future
    end

    # Schedule periodic leaderboard updates
    schedule_periodic_jobs

    Rails.logger.info "Started monitoring #{@futures.length} log files with tail -f background processing"
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

  # Borrar archivos de log que estamos monitoreando
  def reset_log_files
    Rails.logger.info "🔄 Resetting log files..."

    @log_locations.each do |tool, location|
      expanded_path = File.expand_path(location)

      if File.exist?(expanded_path)
        # Truncar el archivo en lugar de eliminarlo para mantener permisos
        File.truncate(expanded_path, 0)
        Rails.logger.info "✅ Truncated log file: #{expanded_path}"
      else
        # Crear directorio si es necesario
        dir = File.dirname(expanded_path)
        FileUtils.mkdir_p(dir) unless Dir.exist?(dir)

        # Crear archivo vacío
        FileUtils.touch(expanded_path)
        Rails.logger.info "✅ Created empty log file: #{expanded_path}"
      end
    end
  end

  # Resetear el progreso de los usuarios
  def reset_user_progress
    Rails.logger.info "🔄 Resetting user progress..."

    # Borrar todos los registros de progreso
    count = GameProgress.delete_all
    Rails.logger.info "✅ Deleted #{count} game progress records"

    # Reiniciar usuarios a estado inicial si es necesario
    User.find_each do |user|
      # Crear nuevo progreso para cada usuario
      GameProgress.create!(
        user: user,
        current_level: GameProgress::LEVELS.first,
        total_points: 0,
        current_streak: 0,
        longest_streak: 0,
        completed_objectives: [],
        last_played_at: Time.current
      )
    end

    Rails.logger.info "✅ Created fresh game progress for #{User.count} users"
  end

  # Resetear el leaderboard
  def reset_leaderboard
    Rails.logger.info "🔄 Resetting leaderboard..."

    # Dependiendo de cómo esté implementado el leaderboard
    # Puede ser una tabla separada o calculada desde GameProgress
    if defined?(Leaderboard) && Leaderboard.respond_to?(:delete_all)
      Leaderboard.delete_all
      Rails.logger.info "✅ Leaderboard data cleared"
    else
      # Si el leaderboard se calcula a partir de GameProgress
      # ya está reseteado al limpiar GameProgress
      Rails.logger.info "✅ Leaderboard will be recalculated from fresh game progress"
    end

    # Forzar actualización del leaderboard
    LeaderboardUpdateJob.perform_now if defined?(LeaderboardUpdateJob)
  end

  # Método para monitorear usando tail -f
  def monitor_log_file_tail(tool, file_path)
    begin
      Rails.logger.info "[LogMonitorService] Monitoring #{tool} log with tail -F: #{file_path}"
      IO.popen(["tail", "-F", file_path]) do |io|
        while @monitoring && !io.eof?
          line = io.gets
          Rails.logger.info "[LogMonitorService] Detected new line in #{tool}: '#{line&.strip}'"
          next if line.nil? || line.strip.empty?
          process_new_commands(tool, line)
        end
      end
    rescue => e
      Rails.logger.error "Error monitoring #{tool} log with tail -f: #{e.message}"
      sleep 5
      retry if @monitoring
    end
  end

  # Se deja el método anterior por compatibilidad si se requiere
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
    Rails.logger.info "[LogMonitorService] Enqueuing LogProcessingJob for #{tool}: '#{content&.strip}'"
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
