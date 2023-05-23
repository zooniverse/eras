class AddCompositePrimaryKeyToClassificationEvents < ActiveRecord::Migration[7.0]
  def change
    execute <<~SQL
      ALTER TABLE classification_events ADD PRIMARY KEY(classification_id, event_time);
    SQL
  end
end
