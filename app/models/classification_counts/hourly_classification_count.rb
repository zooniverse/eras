# frozen_string_literal: true

module ClassificationCounts
  class HourlyClassificationCount < ApplicationRecord
    self.table_name = 'hourly_classification_count'
    attribute :classification_count, :integer

    def readonly?
      true
    end
  end
end
