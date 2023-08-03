# frozen_string_literal: true

module UserGroupClassificationCounts
  class DailyGroupProjectClassificationCount < ApplicationRecord
    self.table_name = 'daily_group_classification_count_and_time_per_project'
    attribute :classification_count, :integer
    attribute :count, :integer
    attribute :total_session_time, :float
    attribute :session_time, :float
    attribute :project_id, :integer
    attribute :user_group_id, :integer

    def readonly?
      true
    end
  end
end
