class User < ApplicationRecord
  has_many :posts, dependent: :destroy
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true

  def full_info
    # Problema intencional para debugging
    debugger  # Para byebug/debug
    "#{name} - #{email} (Posts: #{posts.count})"
  end
end
