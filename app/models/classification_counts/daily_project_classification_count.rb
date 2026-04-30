# frozen_string_literal: true

module ClassificationCounts
  class DailyProjectClassificationCount < ApplicationRecord
    self.table_name = 'daily_classification_count_and_time_per_project'
    attribute :classification_count, :integer
    attribute :total_session_time, :integer

    def readonly?
      true
    end
  end
end
