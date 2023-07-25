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

    factory :user_diff_proj_classification_count do
      project_id { 3 }
    end

    factory :user_diff_period_classification_count do
      period { Date.today - 1 }
    end
  end
end
