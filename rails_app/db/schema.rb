# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_09_12_173951) do
  create_table "game_progresses", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "current_level", default: "rookie", null: false
    t.integer "total_points", default: 0, null: false
    t.text "objectives_completed", default: "[]"
    t.integer "current_streak", default: 0, null: false
    t.integer "longest_streak", default: 0, null: false
    t.integer "hints_used", default: 0, null: false
    t.integer "resets_count", default: 0, null: false
    t.datetime "last_played_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["current_level"], name: "index_game_progresses_on_current_level"
    t.index ["total_points"], name: "index_game_progresses_on_total_points"
    t.index ["user_id"], name: "index_game_progresses_on_user_id"
  end

  create_table "posts", force: :cascade do |t|
    t.string "title", null: false
    t.text "content"
    t.boolean "published", default: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role", default: "user", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "game_progresses", "users"
  add_foreign_key "posts", "users"
end
