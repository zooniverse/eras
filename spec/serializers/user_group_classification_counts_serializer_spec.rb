# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserGroupClassificationCountsSerializer do
  let(:user_group_classification_count) { build(:daily_group_classification_count) }
  let(:active_user_count) { build(:daily_group_count_per_user) }
  let(:project_contributions_count) { build(:daily_group_count_per_project) }
  let(:count_serializer) { described_class.new([user_group_classification_count], [active_user_count], [project_contributions_count]) }

  it 'returns total_count, time_spent, and active_users and project_contributions when no option params given' do
    serialized = count_serializer.as_json(serializer_options: {})
    expect(serialized).to have_key(:total_count)
    expect(serialized).to have_key(:time_spent)
    expect(serialized).to have_key(:project_contributions)
    expect(serialized).not_to have_key(:data)
    expect(serialized[:total_count]).to eq(user_group_classification_count.count)
    expect(serialized[:time_spent]).to eq(user_group_classification_count.session_time)
    expect(serialized[:active_users]).to eq(1)
    expect(serialized[:project_contributions].length).to eq(1)
  end

  it 'returns correct project_contributions when no option params given' do
    serialized = count_serializer.as_json(serializer_options: {})
    expect(serialized[:project_contributions].length).to eq(1)
    expect(serialized[:project_contributions][0].project_id).to eq(project_contributions_count.project_id)
    expect(serialized[:project_contributions][0].count).to eq(project_contributions_count.count)
  end

  it 'does not return response with project_contributions if project_contributions is nil' do
    group_count_serializer = described_class.new([user_group_classification_count], [active_user_count], nil)
    serialized = group_count_serializer.as_json(serializer_options: {})
    expect(serialized).not_to have_key(:project_contributions)
  end

  it 'adds top_contributors to response when querying for top_contributors' do
    serialized = count_serializer.as_json(serializer_options: { top_contributors: 10 })
    expect(serialized).to have_key(:top_contributors)
    expect(serialized[:top_contributors].length).to eq(1)
    expect(serialized[:top_contributors][0].user_id).to eq(active_user_count.user_id)
    expect(serialized[:top_contributors][0].count).to eq(active_user_count.count)
  end

  it 'adds data to response when period is given' do
    serialized = count_serializer.as_json(serializer_options: { period: 'year' })
    expect(serialized).to have_key(:total_count)
    expect(serialized).to have_key(:data)
    expect(serialized[:data].length).to eq(1)
  end

  it 'sums up total_count correctly' do
    count2 = build(:daily_group_classification_count)
    classification_counts = [user_group_classification_count, count2]
    serializer = described_class.new(classification_counts, [], [])
    serialized = serializer.as_json(serializer_options: {})
    expect(serialized[:total_count]).to eq(classification_counts.sum(&:count))
  end

  it 'sums up time_spent correctly' do
    count2 = build(:daily_group_classification_count)
    classification_counts = [user_group_classification_count, count2]
    serializer = described_class.new(classification_counts, [], [])
    serialized = serializer.as_json(serializer_options: {})
    expect(serialized[:time_spent]).to eq(classification_counts.sum(&:session_time))
  end

  it 'shows the correct number of top_contributors given top_contributors limit' do
    active_user_count2 = build(:daily_group_count_per_user)
    active_user_count2.user_id = 2
    serializer = described_class.new([], [active_user_count, active_user_count2], [])
    serialized = serializer.as_json(serializer_options: { top_contributors: 1 })
    expect(serialized[:top_contributors].length).to eq(1)
  end
end
