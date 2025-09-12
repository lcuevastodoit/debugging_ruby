class LeaderboardUpdateJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Starting leaderboard update job"

    begin
      # Update global leaderboard rankings
      update_global_rankings

      # Update level-based rankings
      update_level_rankings

      # Update streaks and achievements
      update_streaks_and_achievements

      # Broadcast updates to connected users
      broadcast_leaderboard_updates

      Rails.logger.info "Leaderboard update job completed successfully"
    rescue => e
      Rails.logger.error "Leaderboard update job failed: #{e.message}"
      retry_job wait: 5.minutes
    end
  end

  private

  def update_global_rankings
    # Calculate rankings for all users
    users_with_progress = User.joins(:game_progress)
                             .includes(:game_progress)
                             .order('game_progresses.total_points DESC',
                                    'game_progresses.current_streak DESC')

    users_with_progress.each_with_index do |user, index|
      # Cache user ranking for quick access
      Rails.cache.write("user_rank_#{user.id}", index + 1, expires_in: 1.hour)
    end
  end

  def update_level_rankings
    GameProgress::LEVELS.each do |level|
      level_users = User.joins(:game_progress)
                       .includes(:game_progress)
                       .where(game_progresses: { current_level: level })
                       .order('game_progresses.total_points DESC')
                       .limit(10)

      # Cache level-specific leaderboards
      Rails.cache.write("leaderboard_#{level}", level_users.to_a, expires_in: 30.minutes)
    end
  end

  def update_streaks_and_achievements
    GameProgress.find_each do |progress|
      # Check for streak achievements
      if progress.current_streak >= 10 && progress.current_streak == progress.longest_streak
        # Award streak achievement
        award_streak_achievement(progress.user, progress.current_streak)
      end

      # Check for completion milestones
      completed_count = progress.completed_objectives.length
      if [5, 10, 15].include?(completed_count)
        award_completion_milestone(progress.user, completed_count)
      end
    end
  end

  def broadcast_leaderboard_updates
    # Broadcast updated leaderboard to all connected users
    Turbo::StreamsChannel.broadcast_replace_to(
      "leaderboard_updates",
      target: "global_leaderboard",
      partial: "debugging_game/leaderboard_table",
      locals: {
        leaderboard: User.joins(:game_progress)
                        .order('game_progresses.total_points DESC')
                        .limit(10)
                        .includes(:game_progress)
      }
    )
  end

  def award_streak_achievement(user, streak_count)
    Rails.logger.info "Awarding streak achievement to user #{user.id}: #{streak_count} streak"

    # Broadcast achievement notification
    Turbo::StreamsChannel.broadcast_append_to(
      "user_#{user.id}_notifications",
      target: "notifications",
      partial: "debugging_game/achievement_notification",
      locals: {
        achievement_type: "streak",
        streak_count: streak_count,
        timestamp: Time.current
      }
    )
  end

  def award_completion_milestone(user, completed_count)
    Rails.logger.info "Awarding completion milestone to user #{user.id}: #{completed_count} objectives"

    # Broadcast milestone notification
    Turbo::StreamsChannel.broadcast_append_to(
      "user_#{user.id}_notifications",
      target: "notifications",
      partial: "debugging_game/milestone_notification",
      locals: {
        milestone_type: "completion",
        completed_count: completed_count,
        timestamp: Time.current
      }
    )
  end
end
