# frozen_string_literal: true

module UserGroupClassificationCounts
  class DailyGroupClassificationCount < ApplicationRecord
    self.table_name = 'daily_group_classification_count_and_time'
    attribute :classification_count, :integer
    attribute :count, :integer
    attribute :total_session_time, :float
    attribute :session_time, :float
    attribute :user_group_id, :integer
    attribute :period, :datetime

    def readonly?
      true
    end
  end
end
