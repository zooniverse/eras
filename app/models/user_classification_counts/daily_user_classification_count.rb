# frozen_string_literal: true

module UserClassificationCounts
  class DailyUserClassificationCount < ApplicationRecord
    self.table_name = 'daily_user_classification_count_and_time'
    attribute :classification_count, :integer
    attribute :total_session_time, :integer
    attribute :user_id, :integer

    def readonly?
      true
    end
  end
end
