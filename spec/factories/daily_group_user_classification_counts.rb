# frozen_string_literal: true

FactoryBot.define do
  factory :daily_group_count_per_user, class: 'UserGroupClassificationCounts::DailyGroupUserClassificationCount' do
    day { Date.today }
    classification_count { 212 }
    count { 212 }
    total_session_time { 10 }
    session_time { 10 }
    user_id { 1 }
  end
end
