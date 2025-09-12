class CommandValidationJob
  include Sidekiq::Job

  def perform(tool, command, timestamp)
    return if command.blank?
    
    Rails.logger.info "Processing command from #{tool}: #{command}"
    
    # Find current active users (those who played recently)
    active_users = User.joins(:game_progress)
                      .where('game_progresses.last_played_at > ?', 1.hour.ago)
    
    active_users.each do |user|
      process_command_for_user(user, tool, command, timestamp)
    end
  end

  private

  def process_command_for_user(user, tool, command, timestamp)
    game_progress = user.game_progress
    return unless game_progress
    
    # Get current level objectives
    current_objectives = objectives_for_level(game_progress.current_level)
    
    # Find incomplete objectives for this user
    incomplete_objectives = current_objectives.reject do |obj|
      game_progress.objective_completed?(obj['key'])
    end
    
    incomplete_objectives.each do |objective|
      if command_matches_objective?(command, objective)
        complete_objective_for_user(user, objective, tool, timestamp)
        break # Only complete one objective per command
      end
    end
  end

  def command_matches_objective?(command, objective)
    expected_commands = objective['expected_commands'] || []
    
    expected_commands.any? do |expected|
      # Flexible matching - check if the command contains the expected pattern
      case expected.downcase
      when /^user\.new/
        command.match?(/user\.new/i)
      when 'inspect', '@user.inspect'
        command.match?(/\.inspect|inspect\s*$|^inspect/i)
      when 'p @user', 'p'
        command.match?(/^p\s+|^p$/)
      when 'save'
        command.match?(/\.save|^save/i)
      when 'post.new'
        command.match?(/post\.new/i)
      when 'ls'
        command.match?(/^ls\s|^ls$/i)
      when 'show-method'
        command.match?(/show-method/i)
      when 'cd'
        command.match?(/^cd\s/i)
      when 'methods'
        command.match?(/\.methods|^methods/i)
      when 'user.all'
        command.match?(/user\.all/i)
      when 'where'
        command.match?(/\.where/i)
      when 'find_by'
        command.match?(/\.find_by/i)
      when 'count'
        command.match?(/\.count/i)
      when 'break'
        command.match?(/^break\s|binding\.pry|debugger|byebug/i)
      when 'step', 'next', 'continue', 'finish'
        command.match?(/^#{expected}$/i)
      when 'backtrace', 'up', 'down', 'caller'
        command.match?(/^#{expected}/i)
      else
        # Exact or partial match for other commands
        command.downcase.include?(expected.downcase)
      end
    end
  end

  def complete_objective_for_user(user, objective, tool, timestamp)
    game_progress = user.game_progress
    
    # Calculate points (base points + bonuses)
    points = calculate_points(objective, timestamp, game_progress)
    
    # Update progress
    game_progress.mark_objective_completed(objective['key'])
    game_progress.add_points(points)
    game_progress.current_streak += 1
    game_progress.longest_streak = [game_progress.longest_streak, game_progress.current_streak].max
    game_progress.last_played_at = Time.current
    
    game_progress.save!
    
    check_level_up(game_progress)
    
    # Broadcast update to UI
    broadcast_progress_update(user, objective, points, tool)
    
    Rails.logger.info "User #{user.id} completed objective #{objective['key']} for #{points} points"
  end

  def calculate_points(objective, timestamp, game_progress)
    base_points = objective['points'] || 100
    
    # Time bonus (if objective has time_limit)
    time_bonus = 1.0
    if objective['time_limit']
      elapsed = Time.current.to_f - timestamp
      time_ratio = elapsed / objective['time_limit']
      
      if time_ratio < 0.25
        time_bonus = Settings.debugging_game.scoring.time_bonus.under_25_percent
      elsif time_ratio < 0.50
        time_bonus = Settings.debugging_game.scoring.time_bonus.under_50_percent
      end
    end
    
    # Streak bonus
    streak_bonus = 1.0
    current_streak = game_progress.current_streak
    
    if current_streak >= 10
      streak_bonus = Settings.debugging_game.scoring.streak_bonus['10_consecutive']
    elsif current_streak >= 5
      streak_bonus = Settings.debugging_game.scoring.streak_bonus['5_consecutive']
    end
    
    (base_points * time_bonus * streak_bonus).round
  end

  def check_level_up(game_progress)
    levels = Settings.debugging_game.levels.to_h
    current_level_index = GameProgress::LEVELS.index(game_progress.current_level)
    return if current_level_index.nil? || current_level_index >= GameProgress::LEVELS.length - 1
    
    next_level = GameProgress::LEVELS[current_level_index + 1]
    next_level_config = levels[next_level]
    
    if next_level_config && game_progress.total_points >= next_level_config['min_points']
      game_progress.update!(current_level: next_level)
      Rails.logger.info "User #{game_progress.user_id} leveled up to #{next_level}!"
      
      # Broadcast level up
      broadcast_level_up(game_progress.user, next_level)
    end
  end

  def objectives_for_level(level)
    Settings.debugging_game.objectives.select { |obj| obj['level'] == level }
  end

  def broadcast_progress_update(user, objective, points, tool)
    # Broadcast real-time updates via Turbo Streams
    Turbo::StreamsChannel.broadcast_update_to(
      "user_#{user.id}_progress",
      target: "live_status",
      partial: "debugging_game/live_status",
      locals: { 
        game_progress: user.game_progress,
        objective: objective,
        points_earned: points,
        tool_used: tool
      }
    )
    
    # Broadcast objective completion notification
    Turbo::StreamsChannel.broadcast_append_to(
      "user_#{user.id}_notifications",
      target: "notifications",
      partial: "debugging_game/objective_completed",
      locals: { 
        objective: objective,
        points: points,
        tool: tool,
        timestamp: Time.current
      }
    )
    
    Rails.logger.info "Broadcasting: User #{user.id} completed #{objective['key']} (+#{points} pts) via #{tool}"
  end

  def broadcast_level_up(user, new_level)
    # This will be implemented when we add Turbo Streams
    Rails.logger.info "Broadcasting level up for user #{user.id} to #{new_level}"
  end
end
