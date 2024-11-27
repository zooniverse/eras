class AddAlreadySeenToClassificationEvents < ActiveRecord::Migration[7.0]
  def change
    add_column :classification_events, :already_seen, :boolean
  end
end
