class LogProcessingJob < ApplicationJob
  queue_as :high_priority

  def perform(log_file_path, tool_name, user_id = nil)
    return unless File.exist?(log_file_path)

    Rails.logger.info "Processing #{tool_name} log file: #{log_file_path}"

    begin
      # Process log file in chunks for better memory management
      process_log_in_chunks(log_file_path, tool_name, user_id)
    rescue => e
      Rails.logger.error "Failed to process log file #{log_file_path}: #{e.message}"
      # Retry with exponential backoff
      retry_job wait: 30.seconds, queue: :low_priority
    end
  end

  private

  def process_log_in_chunks(log_file_path, tool_name, user_id)
    chunk_size = 100 # Process 100 lines at a time
    commands_buffer = []

    File.open(log_file_path, 'r') do |file|
      file.each_slice(chunk_size) do |lines|
        lines.each do |line|
          command = extract_command_from_line(line.strip, tool_name)
          next unless command

          commands_buffer << {
            command: command,
            tool: tool_name,
            timestamp: extract_timestamp(line),
            user_id: user_id
          }
        end

        # Process accumulated commands in batches
        if commands_buffer.length >= 10
          process_command_batch(commands_buffer)
          commands_buffer.clear
        end
      end

      # Process any remaining commands
      process_command_batch(commands_buffer) unless commands_buffer.empty?
    end
  end

  def extract_command_from_line(line, tool)
    case tool.to_s
    when 'pry'
      # Extract Pry commands (after pry prompt)
      if line.match(/\[\d+\] pry\(.*?\)> (.+)/)
        $1.strip
      end
    when 'irb'
      # Extract IRB commands
      if line.match(/irb\(.*?\):\d+:\d+> (.+)/)
        $1.strip
      end
    when 'debug'
      # Extract debug commands
      if line.match(/\(rdbg\) (.+)/)
        $1.strip
      end
    when 'byebug'
      # Extract byebug commands
      if line.match(/\(byebug\) (.+)/)
        $1.strip
      end
    else
      # Generic extraction
      line if line.present?
    end
  end

  def extract_timestamp(line)
    # Try to extract timestamp from log line
    timestamp_match = line.match(/\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\]/)
    if timestamp_match
      Time.parse(timestamp_match[1]) rescue Time.current
    else
      Time.current
    end
  end

  def process_command_batch(commands_batch)
    return if commands_batch.empty?

    commands_batch.each do |command_data|
      # Enqueue individual command validation jobs
      CommandValidationJob.perform_later(
        command_data[:user_id],
        command_data[:command],
        command_data[:tool],
        command_data[:timestamp]
      )
    end

    Rails.logger.info "Enqueued #{commands_batch.length} command validation jobs"
  end
end
