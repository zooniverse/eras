# frozen_string_literal: true

FactoryBot.define do
  factory :daily_classification_count, class: 'ClassificationCounts::DailyClassificationCount' do
    day { Date.today }
    classification_count { 212 }
    period { Date.today }
    count { 212 }
  end
end
