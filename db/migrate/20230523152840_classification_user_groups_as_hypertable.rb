class ClassificationUserGroupsAsHypertable < ActiveRecord::Migration[7.0]
  def change
    execute "SELECT create_hypertable('classification_user_groups', 'event_time');"
  end
end
