class CreateClassificationEventsTable < ActiveRecord::Migration[7.0]
  def change
    create_table :classification_events, primary_key: %i[classification_id event_time], id: false do |t|
      t.bigint :classification_id, null: false
      t.timestamp :event_time, null: false
      t.timestamp :classification_updated_at
      t.timestamp :started_at
      t.timestamp :finished_at
      t.bigint :project_id
      t.bigint :workflow_id
      t.bigint :user_id
      t.bigint :user_group_ids, array: true, default: []
      t.float :session_time

      t.timestamps
    end

    execute "SELECT create_hypertable('classification_events', 'event_time');"
  end
end
