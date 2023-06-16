class ChangeSessionTimeToBeDecimal < ActiveRecord::Migration[7.0]
  def change
    change_column :classification_events, :session_time, :decimal, :precision => 15, :scale => 10
    change_column :classification_user_groups, :session_time, :decimal, :precision => 15, :scale => 10
  end
end
