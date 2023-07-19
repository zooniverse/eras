# frozen_string_literal: true

FactoryBot.define do
  factory :daily_user_project_classification_count, class: 'UserClassificationCounts::DailyUserProjectClassificationCount' do
    day { Date.today }
    classification_count { 212 }
    period { Date.today }
    count { 212 }
    user_id { 1 }
    project_id { 2 }
    session_time { 10 }
  end
end
