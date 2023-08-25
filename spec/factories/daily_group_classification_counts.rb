# frozen_string_literal: true

FactoryBot.define do
  factory :daily_group_classification_count, class: 'UserGroupClassificationCounts::DailyGroupClassificationCount' do
    day { Date.today }
    classification_count { 212 }
    period { Date.today }
    count { 212 }
    session_time { 10 }
  end
end
