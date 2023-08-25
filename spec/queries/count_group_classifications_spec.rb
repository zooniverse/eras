# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CountGroupClassifications do
  let(:params) { {} }
  let(:group_classifications_query) { described_class.new(params) }
  describe 'relation' do
    it 'returns DailyGroupClassificationCount if not given workflow, project id' do
      expect(group_classifications_query.counts.model).to be UserGroupClassificationCounts::DailyGroupClassificationCount
    end

    it 'returns DailyGroupWorkflowClassificationCount if workflow_id given' do
      params[:workflow_id] = 2
      expect(group_classifications_query.counts.model).to be UserGroupClassificationCounts::DailyGroupWorkflowClassificationCount
    end

    it 'returns DailyGroupProjectClassificationCount if project_id given' do
      params[:project_id] = 2
      expect(group_classifications_query.counts.model).to be UserGroupClassificationCounts::DailyGroupProjectClassificationCount
    end
  end

  describe 'select_clause' do
    it 'buckets counts by year by default' do
      counts = group_classifications_query.call(params)
      expected_select_query = "SELECT time_bucket('1 year', day) AS period, SUM(classification_count)::integer AS count, SUM(total_session_time)::float AS session_time FROM \"daily_group_classification_count_and_time\" GROUP BY period ORDER BY period"
      expect(counts.to_sql).to eq(expected_select_query)
    end

    it 'buckets counts by given period' do
      params[:period] = 'week'
      counts = group_classifications_query.call(params)
      expected_select_query = "SELECT time_bucket('1 week', day) AS period, SUM(classification_count)::integer AS count, SUM(total_session_time)::float AS session_time FROM \"daily_group_classification_count_and_time\" GROUP BY period ORDER BY period"
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

    it_behaves_like 'is filterable by workflow'
    it_behaves_like 'is filterable by project'
    it_behaves_like 'is filterable by date range'

    it 'filters by given user_group_id' do
      counts = group_classifications_query.call(params)
      expect(counts.to_sql).to include(".\"user_group_id\" = #{classification_user_group.user_id}")
    end

    it 'returns classification counts of given user group' do
      counts = group_classifications_query.call(params)
      # because default is bucket by year and all data created in the same year, we expect counts to look something like
      # [<UserGroupClassificationCounts::DailyGroupClassificationCount period: 01-01-2023, count: 5, session_time: 10>]
      current_year = Date.today.year
      expect(counts.length).to eq(1)
      expect(counts[0].count).to eq(5)
      expect(counts[0].period).to eq("01-01-#{current_year}")
    end

    it 'returns counts bucketed by given period' do
      params[:period] = 'day'
      counts = group_classifications_query.call(params)
      expect(counts.length).to eq(2)
      expect(counts[0].count).to eq(1)
      expect(counts[0].period).to eq((Date.today - 1).to_s)
      expect(counts[1].count).to eq(4)
      expect(counts[1].period).to eq(Date.today.to_s)
    end

    it 'returns counts of events with given workflow' do
      workflow_id = diff_workflow_event.workflow_id
      params[:workflow_id] = workflow_id.to_s
      counts = group_classifications_query.call(params)
      expect(counts.length).to eq(1)
      expect(counts[0].count).to eq(1)
    end

    it 'returns counts of events with given project' do
      project_id = diff_project_event.project_id
      params[:project_id] = project_id.to_s
      counts = group_classifications_query.call(params)
      expect(counts.length).to eq(1)
      expect(counts[0].count).to eq(1)
    end

    it 'returns counts of events within given date range' do
      last_week = Date.today - 7
      yesterday = Date.today - 1
      params[:start_date] = last_week.to_s
      params[:end_date] = yesterday.to_s
      counts = group_classifications_query.call(params)
      expect(counts.length).to eq(1)
      expect(counts[0].count).to eq(1)
    end
  end
end
