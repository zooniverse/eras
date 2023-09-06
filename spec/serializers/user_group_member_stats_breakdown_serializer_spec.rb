# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserGroupMemberStatsBreakdownSerializer do
  let(:user_project_classification_count) { build(:daily_user_project_classification_count) }

  let(:count_serializer) { described_class.new([user_project_classification_count]) }

  it 'returns group_member_stats as array' do
    serialized = count_serializer.as_json({})
    expect(serialized).to have_key(:group_member_stats_breakdown)
    expect(serialized[:group_member_stats_breakdown].length).to eq(1)
    expect(serialized[:group_member_stats_breakdown][0]).to have_key(:user_id)
    expect(serialized[:group_member_stats_breakdown][0]).to have_key(:count)
    expect(serialized[:group_member_stats_breakdown][0]).to have_key(:session_time)
    expect(serialized[:group_member_stats_breakdown][0]).to have_key(:project_contributions)
  end

  it 'sums up total_count per user correctly' do
    count2 = build(:user_diff_proj_classification_count)
    classification_counts = [user_project_classification_count, count2]
    serializer = described_class.new(classification_counts)
    serialized = serializer.as_json({})
    expect(serialized[:group_member_stats_breakdown][0][:count]).to eq(classification_counts.sum(&:count))
  end

  it 'sums up time_spent per user correctly' do
    count2 = build(:user_diff_proj_classification_count)
    classification_counts = [user_project_classification_count, count2]
    serializer = described_class.new(classification_counts)
    serialized = serializer.as_json({})
    expect(serialized[:group_member_stats_breakdown][0][:session_time]).to eq(classification_counts.sum(&:session_time))
  end

  it 'shows project contributions per user correctly' do
    count2 = build(:user_diff_proj_classification_count)
    classification_counts = [user_project_classification_count, count2]
    serializer = described_class.new(classification_counts)
    serialized = serializer.as_json({})
    member_project_contributions = serialized[:group_member_stats_breakdown][0][:project_contributions]
    expect(member_project_contributions.length).to eq(2)
    expect(member_project_contributions[0]).not_to have_key('user_id')
    expect(member_project_contributions[0]).to have_key('project_id')
    expect(member_project_contributions[0]).to have_key('count')
    expect(member_project_contributions[0]).to have_key('session_time')
  end

  it 'shows user project contributions in order by count desc' do
    count2 = build(:user_diff_proj_classification_count)
    count2.count = user_project_classification_count.count + 100
    classification_counts = [user_project_classification_count, count2]
    serializer = described_class.new(classification_counts)
    serialized = serializer.as_json({})
    member_project_contributions = serialized[:group_member_stats_breakdown][0][:project_contributions]
    expect(member_project_contributions[0]['project_id']).to eq(count2.project_id)
    expect(member_project_contributions[0]['count']).to eq(count2.count)
    expect(member_project_contributions[0]['session_time']).to eq(count2.session_time)
    expect(member_project_contributions[1]['project_id']).to eq(user_project_classification_count.project_id)
    expect(member_project_contributions[1]['count']).to eq(user_project_classification_count.count)
    expect(member_project_contributions[1]['session_time']).to eq(user_project_classification_count.session_time)
  end

  it 'shows group_memer_stats_breakdown in order by top contributors' do
    diff_group_member_stats = build(:daily_user_project_classification_count)
    diff_group_member_stats.user_id = 2
    diff_group_member_stats.count = user_project_classification_count.count + 100
    classification_counts = [user_project_classification_count, diff_group_member_stats]
    serializer = described_class.new(classification_counts)
    serialized = serializer.as_json({})
    expect(serialized[:group_member_stats_breakdown].length).to eq(2)
    expect(serialized[:group_member_stats_breakdown][0][:user_id]).to eq(diff_group_member_stats.user_id)
    expect(serialized[:group_member_stats_breakdown][1][:user_id]).to eq(user_project_classification_count.user_id)
  end
end
