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

ActiveRecord::Schema[7.0].define(version: 2024_11_27_220919) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "timescaledb"

  create_table "classification_events", primary_key: ["classification_id", "event_time"], force: :cascade do |t|
    t.bigint "classification_id", null: false
    t.datetime "event_time", precision: nil, null: false
    t.datetime "classification_updated_at", precision: nil
    t.datetime "started_at", precision: nil
    t.datetime "finished_at", precision: nil
    t.bigint "project_id"
    t.bigint "workflow_id"
    t.bigint "user_id"
    t.bigint "user_group_ids", default: [], array: true
    t.float "session_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "already_seen"
    t.index ["event_time"], name: "classification_events_event_time_idx", order: :desc
    t.index ["user_id"], name: "index_classification_events_on_user_id"
  end

  create_table "classification_user_groups", primary_key: ["classification_id", "event_time", "user_group_id", "user_id"], force: :cascade do |t|
    t.bigint "classification_id", null: false
    t.datetime "event_time", precision: nil, null: false
    t.bigint "user_group_id", null: false
    t.float "session_time"
    t.bigint "project_id"
    t.bigint "user_id", null: false
    t.bigint "workflow_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_time"], name: "classification_user_groups_event_time_idx", order: :desc
  end

  create_table "comment_events", primary_key: ["comment_id", "event_time"], force: :cascade do |t|
    t.bigint "comment_id", null: false
    t.datetime "event_time", precision: nil, null: false
    t.datetime "comment_updated_at", precision: nil
    t.bigint "project_id"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_time"], name: "comment_events_event_time_idx", order: :desc
  end

end
