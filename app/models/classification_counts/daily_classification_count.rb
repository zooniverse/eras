# frozen_string_literal: true

module ClassificationCounts
  class DailyClassificationCount < ApplicationRecord
    self.table_name = 'daily_classification_count'
    attribute :classification_count, :integer

    def readonly?
      true
    end
  end
end
