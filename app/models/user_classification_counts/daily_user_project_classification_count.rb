# frozen_string_literal: true

module UserClassificationCounts
  class DailyUserProjectClassificationCount < ApplicationRecord
    self.table_name = 'daily_user_classification_count_and_time_per_project'
    attribute :classification_count, :integer
    attribute :total_session_time, :integer
    attribute :user_id, :integer
    attribute :project_id, :integer
    attribute :session_time, :integer
    attribute :count, :integer
    attribute :period, :datetime

    def readonly?
      true
    end
  end
end
