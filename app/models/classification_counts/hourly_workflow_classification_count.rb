# frozen_string_literal: true

module ClassificationCounts
    class HourlyWorkflowClassificationCount < ApplicationRecord
      self.table_name = 'hourly_classification_count_per_workflow'
      attribute :classification_count, :integer

      def readonly?
        true
      end
    end
  end
