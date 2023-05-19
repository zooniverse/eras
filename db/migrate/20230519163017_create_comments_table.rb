class CreateCommentsTable < ActiveRecord::Migration[7.0]
  def change
    create_table :comment_events, primary_key: %i[comment_id event_time], id: false do |t|
      t.bigint :comment_id, null: false
      t.timestamp :event_time, null: false
      t.timestamp :comment_updated_at
      t.bigint :project_id
      t.bigint :user_id

      t.timestamps
    end

    execute "SELECT create_hypertable('comment_events', 'event_time');"
  end
end
