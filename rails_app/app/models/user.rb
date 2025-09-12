class User < ApplicationRecord
  has_many :posts, dependent: :destroy
  has_one :game_progress, dependent: :destroy
  validates :name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, presence: true, inclusion: { in: %w[user admin] }

  before_validation :normalize_email

  scope :admins, -> { where(role: 'admin') }
  scope :regular_users, -> { where(role: 'user') }

  def admin?
    role == 'admin'
  end

  def display_name
    name.present? ? name : email.split('@').first.humanize
  end

  def ensure_game_progress
    self.game_progress ||= build_game_progress
  end

  def current_game_level
    game_progress&.current_level || 'rookie'
  end

  def total_game_points
    game_progress&.total_points || 0
  end

  private

  def normalize_email
    self.email = email.downcase.strip if email.present?
  end
end
