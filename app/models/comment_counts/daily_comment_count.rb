# frozen_string_literal: true

module CommentCounts
  class DailyCommentCount < ApplicationRecord
    self.table_name = 'daily_comment_count'
    attribute :comment_count, :integer

    def readonly?
      true
    end
  end
end
