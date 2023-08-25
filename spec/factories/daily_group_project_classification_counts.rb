# frozen_string_literal: true

FactoryBot.define do
  factory :daily_group_count_per_project, class: 'UserGroupClassificationCounts::DailyGroupProjectClassificationCount' do
    day { Date.today }
    classification_count { 212 }
    count { 212 }
    session_time { 10 }
    project_id { 1 }
  end
end
