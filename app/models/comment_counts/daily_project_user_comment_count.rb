# frozen_string_literal: true

module CommentCounts
  class DailyProjectUserCommentCount < ApplicationRecord
    self.table_name = 'daily_comment_count_per_project_and_user'
    attribute :comment_count, :integer
    attribute :project_id, :integer
    attribute :user_id, :integer

    def readonly?
      true
    end
  end
end
