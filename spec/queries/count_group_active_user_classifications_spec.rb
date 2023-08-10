# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CountGroupActiveUserClassifications do
  let(:params) { {} }
  let(:group_active_users_query) { described_class.new(params) }
  describe 'relation' do
    it 'returns DailyGroupUserClassificationCount when project_id/workflow_id is not in params' do
      expect(group_active_users_query.counts.model).to be UserGroupClassificationCounts::DailyGroupUserClassificationCount
    end

    it 'returns DailyGroupUserProjectClassificationCount when params[:project_id] given' do
      params[:project_id] = 1
      expect(group_active_users_query.counts.model).to be UserGroupClassificationCounts::DailyGroupUserProjectClassificationCount
    end

    it 'returns DailyGroupUserWorkflowClassificationCount when params[:workflow_id] given' do
      params[:workflow_id] = 1
      expect(group_active_users_query.counts.model).to be UserGroupClassificationCounts::DailyGroupUserWorkflowClassificationCount
    end
  end

  describe 'select_clause' do
    it 'selects user_id and orders users by count' do
      counts = group_active_users_query.call(params)
      expected_select_query = 'SELECT user_id, SUM(classification_count)::integer AS count, SUM(total_session_time)::float AS session_time FROM "daily_group_classification_count_and_time_per_user" '
      expected_select_query += 'GROUP BY "daily_group_classification_count_and_time_per_user"."user_id" ORDER BY count DESC'
      expect(counts.to_sql).to eq(expected_select_query)
    end
  end

  describe '#call' do
    let!(:classification_user_group) { create(:classification_user_group) }
    let!(:diff_project_event) { create(:cug_with_diff_project) }
    let!(:diff_time_event) { create(:cug_created_yesterday) }
    let!(:diff_user_event) {
      create(:cug_with_diff_user)
    }
    let!(:diff_user_group_classification) { create(:cug_with_diff_user_group) }

    before(:each) do
      params[:id] = classification_user_group.user_group_id.to_s
    end

    it_behaves_like 'is filterable by workflow'
    it_behaves_like 'is filterable by project'
    it_behaves_like 'is filterable by date range'

    it 'filters by given user_group_id' do
      counts = group_active_users_query.call(params)
      expect(counts.to_sql).to include(".\"user_group_id\" = #{classification_user_group.user_id}")
    end

    it 'returns user_ids and counts of given user group' do
      counts = group_active_users_query.call(params)
      # expect 2 project_ids and counts for given user_group
      expect(counts.length).to eq(2)
      expect(counts[0].user_id).to eq(classification_user_group.user_id)
      # expect 3 counts for user_id with most classifications of given user group to be:
      # classification_user_group, diff_time_event, diff_project_event
      expect(counts[0].count).to eq(3)
      expect(counts[1].user_id).to eq(diff_user_event.user_id)
      expect(counts[1].count).to eq(1)
    end

    it 'returns counts of events within given date range' do
      last_week = Date.today - 7
      yesterday = Date.today - 1
      params[:start_date] = last_week.to_s
      params[:end_date] = yesterday.to_s
      counts = group_active_users_query.call(params)
      expect(counts.length).to eq(1)
      expect(counts[0].user_id).to eq(diff_time_event.user_id)
      expect(counts[0].count).to eq(1)
    end
  end
end
