# frozen_string_literal: true

module ClassificationCounts
  class HourlyProjectClassificationCount < ApplicationRecord
    self.table_name = 'hourly_classification_count_and_time_per_project'
    attribute :classification_count, :integer
    attribute :session_time, :float

    def readonly?
      true
    end
  end
end
