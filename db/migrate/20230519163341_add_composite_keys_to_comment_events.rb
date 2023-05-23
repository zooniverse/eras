class AddCompositeKeysToCommentEvents < ActiveRecord::Migration[7.0]
  def change
    execute <<~SQL
      ALTER TABLE comment_events ADD PRIMARY KEY(comment_id, event_time);
    SQL
  end
end
