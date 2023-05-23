class CreateClassificationUserGroups < ActiveRecord::Migration[7.0]
  def change
    create_table :classification_user_groups, id: false do |t|
      t.bigint :classification_id
      t.timestamp :event_time, null: false
      t.bigint :user_group_id
      t.float :session_time
      t.bigint :project_id
      t.bigint :user_id
      t.bigint :workflow_id

      t.timestamps
    end
  end
end
