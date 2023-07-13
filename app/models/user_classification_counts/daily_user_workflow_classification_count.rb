# frozen_string_literal: true

module UserClassificationCounts
  class DailyUserWorkflowClassificationCount < ApplicationRecord
    self.table_name = 'daily_user_classification_count_and_time_per_workflow'
    attribute :classification_count, :integer
    attribute :total_session_time, :integer
    attribute :user_id, :integer
    attribute :workflow_id, :integer

    def readonly?
      true
    end
  end
end
