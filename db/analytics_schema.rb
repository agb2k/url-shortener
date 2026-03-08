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

ActiveRecord::Schema[8.1].define(version: 2026_03_05_073000) do
  # TABLE: short_links
  # SQL: CREATE TABLE short_links ( `original_url` String, `short_code` String, `title` Nullable(String), `created_at` DateTime, `updated_at` DateTime, `id` UInt32 ) ENGINE = Log
  create_table "short_links", id: :uint32, options: "Log", force: :cascade do |t|
    t.string "original_url", null: false
    t.string "short_code", null: false
    t.string "title"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "id", null: false
  end

  # TABLE: visits
  # SQL: CREATE TABLE visits ( `short_link_id` UInt64, `created_at` DateTime, `ip_address` Nullable(String), `country` Nullable(String), `user_agent` Nullable(String) ) ENGINE = MergeTree ORDER BY (short_link_id, created_at) SETTINGS index_granularity = 8192
  create_table "visits", id: false, options: "MergeTree ORDER BY (short_link_id, created_at) SETTINGS index_granularity = 8192", force: :cascade do |t|
    t.integer "short_link_id", limit: 8, null: false
    t.datetime "created_at", precision: nil, null: false
    t.string "ip_address"
    t.string "country"
    t.string "user_agent"
  end

end
