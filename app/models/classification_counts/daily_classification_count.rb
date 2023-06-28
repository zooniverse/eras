# frozen_string_literal: true

module ClassificationCounts
  class DailyClassificationCount < ApplicationRecord
    self.table_name = 'daily_classification_count'
    attribute :classification_count, :integer
    attribute :count, :integer
    attribute :period, :datetime

    def readonly?
      true
    end

    def self.refresh
      today = Date.today
      yesterday = today - 1
      sql = "CALL refresh_continuous_aggregate('daily_classification_count', '#{yesterday}', '#{today}')"
      ActiveRecord::Base.connection.execute(sql)
    end
  end
end
