# frozen_string_literal: true

module UserGroupClassificationCounts
  class DailyGroupUserClassificationCount < ApplicationRecord
    self.table_name = 'daily_group_classification_count_and_time_per_user'
    attribute :classification_count, :integer
    attribute :count, :integer
    attribute :total_session_time, :integer
    attribute :session_time, :integer
    attribute :user_id, :integer
    attribute :user_group_id, :integer

    def readonly?
      true
    end
  end
end
