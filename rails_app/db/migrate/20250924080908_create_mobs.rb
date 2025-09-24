class CreateMobs < ActiveRecord::Migration[8.0]
  def change
    create_table :mobs do |t|
      t.string :name
      t.integer :health
      t.integer :attack
      t.integer :defense
      t.text :description

      t.timestamps
    end
  end
end
