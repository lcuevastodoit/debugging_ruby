class DebuggingGameController < ApplicationController
  before_action :set_current_user
  before_action :ensure_game_progress, except: [:reset]

  def index
    @objectives_by_level = Settings.debugging_game.objectives.group_by { |obj| obj['level'] }
    @levels_config = Settings.debugging_game.levels.to_h
    current_level = @game_progress&.current_level || 'rookie'
    @current_level_objectives = @objectives_by_level[current_level] || []
    @leaderboard = User.joins(:game_progress)
                      .order('game_progresses.total_points DESC', 'game_progresses.current_level DESC', 'game_progresses.current_streak DESC')
                      .limit(10)
                      .includes(:game_progress)
    
    @current_user_rank = get_user_rank(@current_user)
    @user_stats = calculate_user_statistics(@current_user)
    @global_stats = calculate_global_statistics
  end

  def show
    @objective_key = params[:objective_key]
    @objective = @all_objectives.find { |obj| obj['key'] == @objective_key }
    
    return redirect_to debugging_game_index_path, alert: 'Objective not found.' unless @objective
    
    @is_completed = @game_progress.objective_completed?(@objective_key)
    @prerequisites = @objective['prerequisites'] || []
    @is_unlocked = objective_unlocked?(@objective)
    @can_attempt = can_attempt_objective?(@objective)
  end

  def reset
    if request.post?
      reset_type = params[:reset_type] || 'progress_only'
      
      case reset_type
      when 'progress_only'
        @game_progress&.reset_progress!
        notice_message = 'Game progress has been reset!'
      when 'progress_and_logs'
        @game_progress&.reset_progress!
        clear_debugging_logs
        notice_message = 'Game progress and debugging logs have been reset!'
      when 'logs_only'
        clear_debugging_logs
        notice_message = 'Debugging logs have been cleared!'
      when 'full_reset'
        # Global reset - delete ALL game progress for ALL users
        Rails.logger.info "Full reset: Destroying all GameProgress records"
        destroyed_count = GameProgress.count
        GameProgress.destroy_all
        Rails.logger.info "Full reset: Destroyed #{destroyed_count} GameProgress records"
        
        clear_debugging_logs
        clear_user_cache
        
        # Set session flag to prevent automatic GameProgress recreation
        session[:full_reset_performed] = true
        
        notice_message = 'GLOBAL RESET performed! All users data has been reset. Starting completely fresh.'
        Rails.logger.info "Full reset completed successfully"
      end
      
      redirect_to debugging_game_index_path, notice: notice_message
    end
  end

  def start_monitoring
    @monitor_service = LogMonitorService.new
    @monitor_service.start_monitoring
    
    respond_to do |format|
      format.turbo_stream { 
        render turbo_stream: turbo_stream.update('monitoring_status', 
          '<div class="text-green-600 font-medium">Monitoring Active 🟢</div>')
      }
      format.html { redirect_to debugging_game_index_path, notice: 'Log monitoring started!' }
    end
  end

  def stop_monitoring
    respond_to do |format|
      format.turbo_stream { 
        render turbo_stream: turbo_stream.update('monitoring_status', 
          '<div class="text-red-600 font-medium">Monitoring Stopped 🔴</div>')
      }
      format.html { redirect_to debugging_game_index_path, notice: 'Log monitoring stopped!' }
    end
  end
  
  def live_status
    if @game_progress
      render json: {
        current_level: @game_progress.current_level,
        total_points: @game_progress.total_points,
        current_streak: @game_progress.current_streak,
        completed_objectives_count: @game_progress.completed_objectives.length,
        level_emoji: @game_progress.level_emoji,
        level_title: @game_progress.level_title,
        updated_at: @game_progress.updated_at
      }
    else
      render json: {
        current_level: 'rookie',
        total_points: 0,
        current_streak: 0,
        completed_objectives_count: 0,
        level_emoji: '🐣',
        level_title: 'Novato',
        updated_at: Time.current,
        reset_performed: true
      }
    end
  end
  
  def get_hint
    return render json: { error: 'No game progress available. Please start playing first.' }, status: :not_found unless @game_progress
    
    objective_key = params[:objective_key]
    objective = @all_objectives.find { |obj| obj['key'] == objective_key }
    
    return render json: { error: 'Objective not found' }, status: :not_found unless objective
    return render json: { error: 'Objective already completed' } if @game_progress.objective_completed?(objective_key)
    
    unless @game_progress.can_use_hint?(objective_key)
      return render json: { error: 'Hint not available for this objective' }
    end
    
    @game_progress.use_hint!
    hint_content = generate_contextual_hint(objective)
    
    render json: {
      hint: hint_content,
      hints_used: @game_progress.hints_used,
      penalty_points: @game_progress.hint_penalty_points
    }
  end

  private

  def current_user
    @current_user
  end

  def set_current_user
    # For demo purposes, create a user if none exists
    @current_user = User.first || User.create!(
      name: 'Demo Player',
      email: 'demo@example.com',
      role: 'user'
    )
  end

  def ensure_game_progress
    # Don't auto-create GameProgress if we just performed a full reset
    if session[:full_reset_performed]
      session.delete(:full_reset_performed)
      @game_progress = nil
    else
      @game_progress = @current_user.game_progress || @current_user.create_game_progress!(
        current_level: 'rookie',
        total_points: 0,
        objectives_completed: [],
        current_streak: 0,
        longest_streak: 0,
        hints_used: 0,
        resets_count: 0,
        last_played_at: Time.current
      )
    end
    
    @all_objectives = Settings.debugging_game.objectives.map(&:to_h)
    @objectives_by_level = @all_objectives.group_by { |obj| obj['level'] }
  end

  def objective_unlocked?(objective)
    return false unless @game_progress
    
    # Check if objective level is unlocked based on points
    level_config = Settings.debugging_game.levels[objective['level'].to_sym]
    level_unlocked = @game_progress.total_points >= level_config[:min_points]
    
    # Check prerequisites
    prerequisites = objective['prerequisites'] || []
    prerequisites_met = prerequisites.all? { |prereq| @game_progress.objective_completed?(prereq) }
    
    level_unlocked && prerequisites_met
  end
  
  def can_attempt_objective?(objective)
    return false unless @game_progress
    
    # Can attempt if objective is unlocked and not already completed
    objective_unlocked?(objective) && !@game_progress.objective_completed?(objective['key'])
  end
  
  def get_user_rank(user)
    return nil unless user.game_progress
    
    User.joins(:game_progress)
        .where('game_progresses.total_points > ? OR (game_progresses.total_points = ? AND game_progresses.id < ?)', 
               user.game_progress.total_points, user.game_progress.total_points, user.game_progress.id)
        .count + 1
  end

  def clear_debugging_logs
    log_locations = Settings.debugging_game.log_locations.to_h
    cleared_logs = []
    
    # Clear debugging tool history files
    log_locations.each do |tool, location|
      next if tool.to_s == 'rails' # Handle Rails log separately
      
      expanded_path = File.expand_path(location)
      
      begin
        if File.exist?(expanded_path) && File.writable?(expanded_path)
          File.truncate(expanded_path, 0)
          cleared_logs << tool.to_s
          Rails.logger.info "Cleared #{tool} log: #{expanded_path}"
        end
      rescue => e
        Rails.logger.error "Failed to clear #{tool} log: #{e.message}"
      end
    end
    
    # Clear Rails development log
    begin
      rails_log_path = Rails.root.join('log', 'development.log')
      if File.exist?(rails_log_path) && File.writable?(rails_log_path)
        # Log before clearing
        Rails.logger.info "Full reset: Clearing Rails development log"
        File.truncate(rails_log_path, 0)
        cleared_logs << 'rails'
        # Since we just cleared the log, we need to reinitialize logging
        Rails.logger.info "Rails development log cleared during full reset"
      end
    rescue => e
      Rails.logger.error "Failed to clear Rails development log: #{e.message}"
    end
    
    cleared_logs
  end
  
  def clear_user_cache
    # Clear any cached user sessions or temporary data
    # In a real app, this might clear Redis cache, session data, etc.
    Rails.cache.clear if Rails.cache.respond_to?(:clear)
    Rails.logger.info "Cleared user cache and temporary data"
  end
  
  def get_log_status
    log_locations = Settings.debugging_game.log_locations.to_h
    status = {}
    
    log_locations.each do |tool, location|
      expanded_path = File.expand_path(location)
      if File.exist?(expanded_path)
        size = File.size(expanded_path)
        lines = File.readlines(expanded_path).length rescue 0
        status[tool] = { size: size, lines: lines, path: expanded_path }
      else
        status[tool] = { size: 0, lines: 0, path: expanded_path, exists: false }
      end
    end
    
    status
  end
  
  def generate_contextual_hint(objective)
    hints = objective['hints'] || []
    return "No hints available for this objective." if hints.empty?
    
    # Progressive hints based on user's current progress
    case @game_progress.current_level
    when 'rookie'
      hints.first || "Start by opening the debugging tool and exploring the application state."
    when 'magician', 'sorcerer'
      hints[1] || hints.first || "Use breakpoints to examine the code execution flow."
    else
      hints.last || "Apply advanced debugging techniques to solve this challenge."
    end
  end
  
  def calculate_user_statistics(user)
    progress = user.game_progress
    return {} unless progress
    
    completed_count = progress.completed_objectives.length
    total_objectives = Settings.debugging_game.objectives.length
    completion_rate = total_objectives > 0 ? (completed_count.to_f / total_objectives * 100).round(1) : 0
    
    {
      completion_rate: completion_rate,
      efficiency_score: calculate_efficiency_score(progress),
      favorite_tool: calculate_favorite_tool(user),
      avg_time_per_objective: calculate_avg_time_per_objective(progress),
      best_streak: progress.longest_streak,
      hints_per_objective: completed_count > 0 ? (progress.hints_used.to_f / completed_count).round(1) : 0,
      level_progress: calculate_level_progress(progress)
    }
  end
  
  def calculate_global_statistics
    total_users = User.joins(:game_progress).count
    # Calculate total objectives completed by iterating through all progress records
    total_objectives_completed = GameProgress.includes(:user).sum { |progress| progress.completed_objectives.length }
    avg_completion_rate = total_users > 0 ? (total_objectives_completed.to_f / (total_users * 16) * 100).round(1) : 0
    
    {
      total_players: total_users,
      total_objectives_completed: total_objectives_completed,
      avg_completion_rate: avg_completion_rate,
      most_popular_level: calculate_most_popular_level,
      highest_streak: GameProgress.maximum(:longest_streak) || 0,
      total_hints_used: GameProgress.sum(:hints_used)
    }
  end
  
  def calculate_efficiency_score(progress)
    return 0 if progress.completed_objectives.empty?
    
    base_score = progress.total_points
    hint_penalty = progress.hints_used * 5
    reset_penalty = progress.resets_count * 20
    streak_bonus = progress.longest_streak * 10
    
    [(base_score - hint_penalty - reset_penalty + streak_bonus), 0].max
  end
  
  def calculate_favorite_tool(user)
    # This would require tracking tool usage, for now return placeholder
    ['pry', 'debug', 'byebug', 'irb'].sample
  end
  
  def calculate_avg_time_per_objective(progress)
    # Placeholder calculation - would need to track objective completion times
    return "N/A" if progress.completed_objectives.empty?
    "~15 min"
  end
  
  def calculate_level_progress(progress)
    current_level_index = GameProgress::LEVELS.index(progress.current_level) || 0
    ((current_level_index + 1).to_f / GameProgress::LEVELS.length * 100).round(1)
  end
  
  def calculate_most_popular_level
    GameProgress.group(:current_level).count.max_by { |level, count| count }&.first || 'rookie'
  end
end
