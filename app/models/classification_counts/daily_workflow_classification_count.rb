# frozen_string_literal: true
module ClassificationCounts
  class DailyWorkflowClassificationCount < ApplicationRecord
    self.table_name = 'daily_classification_count_per_workflow'
    attribute :classification_count, :integer

    def readonly?
      true
    end
  end
end
