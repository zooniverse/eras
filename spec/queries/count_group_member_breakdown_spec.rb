# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CountGroupMemberBreakdown do
  let(:params) { {} }
  let(:group_member_breakdown_query) { described_class.new }
  describe 'relation' do
    it 'returns DailyGroupUserProjectClassificationCount' do
      expect(group_member_breakdown_query.counts.model).to be UserGroupClassificationCounts::DailyGroupUserProjectClassificationCount
    end
  end

  describe 'select_clause' do
    it 'selects user_id, project_id, sum of counts and time' do
      counts = group_member_breakdown_query.call(params)
      expected_select_query = 'SELECT user_id, project_id, SUM(classification_count)::integer AS count, SUM(total_session_time)::float AS session_time '
      expected_select_query += 'FROM "daily_group_classification_count_and_time_per_user_per_project" '
      expected_select_query += 'GROUP BY user_id, project_id'
      expect(counts.to_sql).to eq(expected_select_query)
    end
  end

  describe '#call' do
    let!(:classification_user_group) { create(:classification_user_group) }
    let!(:diff_workflow_event) { create(:cug_with_diff_workflow) }
    let!(:diff_project_event) { create(:cug_with_diff_project) }
    let!(:diff_time_event) { create(:cug_created_yesterday) }
    let!(:diff_user_classification) { create(:cug_with_diff_user) }
    let!(:diff_user_group_classification) { create(:cug_with_diff_user_group) }

    before(:each) do
      params[:id] = classification_user_group.user_group_id.to_s
    end

    it_behaves_like 'is filterable by date range' do
      let(:counts_query) { described_class.new }
    end

    it 'filters by given user_group_id' do
      counts = group_member_breakdown_query.call(params)
      expect(counts.to_sql).to include(".\"user_group_id\" = #{classification_user_group.user_id}")
    end

    it 'returns classification counts of given user group grouped by user and project' do
      counts = group_member_breakdown_query.call(params)
      # because default is grouped by project_id and user_id, we expect results to look something like:
      # [
      # <UserGroupClassificationCounts::DailyGroupUserProjectClassificationCount user_id: 1, project_id: 1, count: 3, session_time: 10>,
      # <UserGroupClassificationCounts::DailyGroupUserProjectClassificationCount user_id: 1, project_id: 2, count: 1, session_time: 10>,
      # <UserGroupClassificationCounts::DailyGroupUserProjectClassificationCount user_id: 2, project_id: 1, count: 3, session_time: 10>
      # ]
      expect(counts.length).to eq(3)
      # the 3 for user_id: 1, project_id:1 being
      # [classification_user_group, diff_workflow_event, diff_time_event]
      expect(counts[0].count).to eq(3)
      expect(counts[1].count).to eq(1)
      expect(counts[1].count).to eq(1)
    end

    it 'returns counts of events within given date range' do
      last_week = Date.today - 7
      yesterday = Date.today - 1
      params[:start_date] = last_week.to_s
      params[:end_date] = yesterday.to_s
      counts = group_member_breakdown_query.call(params)
      expect(counts.length).to eq(1)
      expect(counts[0].count).to eq(1)
      expect(counts[0].project_id).to eq(diff_time_event.project_id)
      expect(counts[0].user_id).to eq(diff_time_event.user_id)
    end
  end
end
