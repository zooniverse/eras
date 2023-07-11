# frozen_string_literal: true

FactoryBot.define do
  factory :comment_event do
    event_time { Date.today }
    comment_updated_at { Date.today }
    comment_id { 1 }
    user_id { 1 }

    factory :comment_created_yesterday do
      event_time { Date.today - 1 }
      comment_id { 2 }
    end

    factory :comment_with_project do
      project_id { 3 }
      comment_id { 4 }
    end

    factory :comment_with_diff_user do
      user_id { 2 }
      comment_id { 6 }
    end
  end
end
