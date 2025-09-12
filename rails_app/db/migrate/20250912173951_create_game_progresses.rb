class CreateGameProgresses < ActiveRecord::Migration[8.0]
  def change
    create_table :game_progresses do |t|
      t.references :user, null: false, foreign_key: true
      t.string :current_level, default: 'rookie', null: false
      t.integer :total_points, default: 0, null: false
      t.text :objectives_completed, default: '[]'
      t.integer :current_streak, default: 0, null: false
      t.integer :longest_streak, default: 0, null: false
      t.integer :hints_used, default: 0, null: false
      t.integer :resets_count, default: 0, null: false
      t.datetime :last_played_at

      t.timestamps
    end
    
    add_index :game_progresses, :current_level
    add_index :game_progresses, :total_points
  end
end
