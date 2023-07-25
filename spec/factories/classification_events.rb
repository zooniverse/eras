# frozen_string_literal: true

FactoryBot.define do
  factory :classification_event do
    event_time { Date.today }
    classification_updated_at { Date.today }
    classification_id { 10 }
    started_at { Date.today }
    finished_at { Date.today }
    project_id { 1 }
    workflow_id { 1 }
    user_id { 1 }
    user_group_ids { [] }
    session_time { 10 }

    factory :classification_created_yesterday do
      event_time { Date.today - 1 }
      classification_id { 3 }
    end

    factory :classification_with_diff_workflow do
      workflow_id { 3 }
      classification_id { 4 }
    end

    factory :classification_with_diff_project do
      project_id { 2 }
      classification_id { 5 }
    end

    factory :classification_with_diff_user do
      user_id { 2 }
      classification_id { 6 }
    end

    factory :classification_with_diff_session_time do
      session_time { 2 }
      classification_id { 7 }
    end
  end
end
