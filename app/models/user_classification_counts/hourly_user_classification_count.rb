# frozen_string_literal: true

module UserClassificationCounts
  class HourlyUserClassificationCount < ApplicationRecord
    self.table_name = 'hourly_user_classification_count_and_time'
    attribute :classification_count, :integer
    attribute :session_time, :float
    attribute :user_id, :integer

    def readonly?
      true
    end
  end
end
