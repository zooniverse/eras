# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserClassificationCountsSerializer do
  let(:user_classification_count) { build(:daily_user_project_classification_count) }
  let(:count_serializer) { described_class.new([user_classification_count]) }

  it 'returns total_count' do
    serialized = count_serializer.as_json(serializer_options: {})
    expect(serialized).to have_key(:total_count)
    expect(serialized).not_to have_key(:data)
    expect(serialized).not_to have_key(:time_spent)
    expect(serialized).not_to have_key(:project_contributions)
    expect(serialized[:total_count]).to eq(user_classification_count.count)
  end

  it 'returns total_count & time_spent if time_spent is true' do
    serialized = count_serializer.as_json(serializer_options: { time_spent: true })
    expect(serialized).to have_key(:total_count)
    expect(serialized).to have_key(:time_spent)
    expect(serialized[:time_spent]).to eq(user_classification_count.session_time)
  end

  it 'returns total_count and data when period is given' do
    serialized = count_serializer.as_json(serializer_options: { period: 'year' })
    expect(serialized).to have_key(:total_count)
    expect(serialized).to have_key(:data)
    expect(serialized[:data].size).to eq(1)
  end

  it 'sums up total_count correctly' do
    count2 = build(:daily_user_project_classification_count)
    classification_counts = [user_classification_count, count2]
    serializer = described_class.new(classification_counts)
    serialized = serializer.as_json(serializer_options: {})
    expect(serialized[:total_count]).to eq(classification_counts.sum(&:count))
  end

  it 'sums up time_spent correctly' do
    count2 = build(:daily_user_project_classification_count)
    classification_counts = [user_classification_count, count2]
    serializer = described_class.new(classification_counts)
    serialized = serializer.as_json(serializer_options: { time_spent: true })
    expect(serialized[:time_spent]).to eq(classification_counts.sum(&:session_time))
  end

  it 'returns project_contributions if project_contributions' do
    serialized = count_serializer.as_json(serializer_options: { project_contributions: true })
    expect(serialized).to have_key(:total_count)
    expect(serialized).to have_key(:project_contributions)
    expect(serialized[:project_contributions].length).to eq(1)
    expected_project_contributions = { project_id: user_classification_count.project_id, count: user_classification_count.count }
    expect(serialized[:project_contributions][0]).to eq(expected_project_contributions)
  end

  context 'project_contributions param calculations' do
    let(:user_diff_proj_count) { build(:user_diff_proj_classification_count) }
    let(:user_diff_period_classification_count) { build(:user_diff_period_classification_count) }
    let(:serializer) { described_class.new([user_diff_period_classification_count, user_classification_count, user_diff_proj_count]) }

    it 'shows project_contributions ordered desc by count when order_proj_contribution_by by not given' do
      serialized = serializer.as_json(serializer_options: { project_contributions: true })
      expect(serialized[:project_contributions].length).to eq(2)
      expect(serialized[:project_contributions][0][:project_id]).to eq(user_classification_count.project_id)
      expect(serialized[:project_contributions][0][:count]).to eq(user_classification_count.count + user_diff_period_classification_count.count)
      expect(serialized[:project_contributions][1][:project_id]).to eq(user_diff_proj_count.project_id)
      expect(serialized[:project_contributions][1][:count]).to eq(user_diff_proj_count.count)
    end

    context 'when order_project_contributions_by param is given' do
      it 'shows project_contributions ordered desc by count when order_proj_contribution_by is count' do
        serialized = serializer.as_json(serializer_options: { project_contributions: true, order_project_contributions_by: 'count' })
        expect(serialized[:project_contributions].length).to eq(2)
        expect(serialized[:project_contributions][0][:project_id]).to eq(user_classification_count.project_id)
        expect(serialized[:project_contributions][0][:count]).to eq(user_classification_count.count + user_diff_period_classification_count.count)
        expect(serialized[:project_contributions][1][:project_id]).to eq(user_diff_proj_count.project_id)
        expect(serialized[:project_contributions][1][:count]).to eq(user_diff_proj_count.count)
      end

      it 'shows project_contributions ordered by recents when order_proj_contribution_by is recents' do
        classification_count_diff_project_created_yesterday = build(:user_diff_proj_classification_count, period: Date.today - 1)
        serializer = described_class.new([classification_count_diff_project_created_yesterday,user_classification_count])
        serialized = serializer.as_json(serializer_options: { project_contributions: true, order_project_contributions_by: 'recents' })
        expect(serialized[:project_contributions].length).to eq(2)
        expect(serialized[:project_contributions][0][:project_id]).to eq(user_classification_count.project_id)
        expect(serialized[:project_contributions][0][:count]).to eq(user_classification_count.count)
        expect(serialized[:project_contributions][1][:project_id]).to eq(classification_count_diff_project_created_yesterday.project_id)
        expect(serialized[:project_contributions][1][:count]).to eq(classification_count_diff_project_created_yesterday.count)
      end
    end

    it 'shows response data bucketed by period when querying project_contributions by count' do
      serialized = serializer.as_json(serializer_options: { project_contributions: true, period: 'day' })
      expect(serialized[:data].length).to eq(2)
      expect(serialized[:data][0][:period]).to eq(user_diff_period_classification_count.period)
      expect(serialized[:data][0][:count]).to eq(user_diff_period_classification_count.count)
      expect(serialized[:data][0]).not_to have_key(:session_time)
      expect(serialized[:data][1][:period]).to eq(user_classification_count.period)
      expect(serialized[:data][1][:count]).to eq(user_classification_count.count + user_diff_proj_count.count)
    end

    it 'shows response data with session_times bucketed by period' do
      serialized = serializer.as_json(serializer_options: { project_contributions: true, period: 'day', time_spent: true })
      expect(serialized[:data].length).to eq(2)
      expect(serialized[:data][0][:session_time]).to eq(user_diff_period_classification_count.session_time)
      expect(serialized[:data][1][:session_time]).to eq(user_classification_count.session_time + user_diff_proj_count.session_time)
    end
  end
end
