class AddUniqueIndexToClassificationUserGroups < ActiveRecord::Migration[7.0]
  def change
    execute <<~SQL
      ALTER TABLE classification_user_groups ADD PRIMARY KEY(classification_id, event_time, user_group_id, user_id);
    SQL
  end
end
