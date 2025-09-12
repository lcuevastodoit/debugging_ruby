class GameProgress < ApplicationRecord
  belongs_to :user

  LEVELS = %w[rookie magician sorcerer hero expert astro star final_boss].freeze

  validates :current_level, presence: true, inclusion: { in: LEVELS }
  validates :total_points, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :current_streak, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :longest_streak, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :hints_used, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :resets_count, presence: true, numericality: { greater_than_or_equal_to: 0 }

  serialize :objectives_completed, coder: JSON

  def completed_objectives
    objectives_completed || []
  end

  def mark_objective_completed(objective_key)
    completed = completed_objectives
    completed << objective_key unless completed.include?(objective_key)
    self.objectives_completed = completed
    check_level_progression!
  end

  def add_points(points)
    self.total_points += points
    check_level_progression!
  end

  def objective_completed?(objective_key)
    completed_objectives.include?(objective_key)
  end

  def reset_progress!
    update!(
      current_level: 'rookie',
      total_points: 0,
      objectives_completed: [],
      current_streak: 0,
      resets_count: resets_count + 1,
      last_played_at: Time.current
    )
  end

  def use_hint!
    self.increment!(:hints_used)
  end

  def can_use_hint?(objective_key)
    # Allow hints after spending some time on an objective
    !objective_completed?(objective_key)
  end

  def hint_penalty_points
    # Small point penalty for using hints to encourage learning
    hints_used * 5
  end

  def level_emoji
    case current_level
    when 'rookie' then '🐣'
    when 'magician' then '🎩'
    when 'sorcerer' then '🔮'
    when 'hero' then '🦸'
    when 'expert' then '🎯'
    when 'astro' then '🚀'
    when 'star' then '⭐'
    when 'final_boss' then '👑'
    else '🎮'
    end
  end

  def level_title
    case current_level
    when 'rookie' then 'Novato'
    when 'magician' then 'Mago'
    when 'sorcerer' then 'Hechicero'
    when 'hero' then 'Héroe'
    when 'expert' then 'Experto'
    when 'astro' then 'Astronauta'
    when 'star' then 'Estrella'
    when 'final_boss' then 'Jefe Final'
    else 'Jugador'
    end
  end

  private

  def check_level_progression!
    levels_config = Settings.debugging_game.levels.to_h
    current_level_index = LEVELS.index(current_level)

    # Check if we can advance to next level
    LEVELS[(current_level_index + 1)..-1].each do |next_level|
      level_config = levels_config[next_level.to_sym]
      if total_points >= level_config[:min_points]
        self.current_level = next_level
      else
        break
      end
    end
  end
end
