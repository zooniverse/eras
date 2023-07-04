# frozen_string_literal: true

module CommentCounts
  class DailyUserCommentCount < ApplicationRecord
    self.table_name = 'daily_comment_count_per_user'
    attribute :comment_count, :integer
    attribute :user_id, :integer

    def readonly?
      true
    end
  end
end
