# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CountUserClassifications do
  let(:params) { {} }
  let(:count_user_classifications) { described_class.new(params) }
  describe 'relation' do
    it 'returns DailyUserClassificationCount if not given workflow, project ids or top_project_contributions' do
      expect(count_user_classifications.counts.model).to be UserClassificationCounts::DailyUserClassificationCount
    end

    it 'returns DailyUserWorkflowClassificationCount if workflow_id given' do
      params[:workflow_id] = 2
      expect(count_user_classifications.counts.model).to be UserClassificationCounts::DailyUserWorkflowClassificationCount
    end

    it 'returns DailyUserProjectClassificationCount if project_id given' do
      params[:project_id] = 2
      expect(count_user_classifications.counts.model).to be UserClassificationCounts::DailyUserProjectClassificationCount
    end

    it 'returns DailyUserProjectClassificationCount if querying top_project_contributions' do
      params[:top_project_contributions] = 2
      expect(count_user_classifications.counts.model).to be UserClassificationCounts::DailyUserProjectClassificationCount
    end
  end

  describe 'select_clause' do
    it 'buckets counts by year by default' do
      counts = count_user_classifications.call(params)
      expected_select_query = "SELECT time_bucket('1 year', day) AS period, SUM(classification_count)::integer AS count FROM \"daily_user_classification_count_and_time\" GROUP BY period ORDER BY period"
      expect(counts.to_sql).to eq(expected_select_query)
    end

    it 'buckets counts by given period' do
      params[:period] = 'week'
      counts = count_user_classifications.call(params)
      expected_select_query = "SELECT time_bucket('1 week', day) AS period, SUM(classification_count)::integer AS count FROM \"daily_user_classification_count_and_time\" GROUP BY period ORDER BY period"
      expect(counts.to_sql).to eq(expected_select_query)
    end

    it 'queries for total session time if querying for time_spent' do
      params[:time_spent] = true
      counts = count_user_classifications.call(params)
      expected_select_query = "SELECT time_bucket('1 year', day) AS period, SUM(classification_count)::integer AS count, SUM(total_session_time)::float AS session_time FROM \"daily_user_classification_count_and_time\" GROUP BY period ORDER BY period"
      expect(counts.to_sql).to eq(expected_select_query)
    end

    it 'queries for project_id if querying for top_project_contributions' do
      params[:top_project_contributions] = 10
      counts = count_user_classifications.call(params)
      expected_select_query = "SELECT time_bucket('1 year', day) AS period, SUM(classification_count)::integer AS count, project_id FROM \"daily_user_classification_count_and_time_per_project\" GROUP BY period, project_id ORDER BY period"
      expect(counts.to_sql).to eq(expected_select_query)
    end
  end

  describe '#call' do
    let!(:classification_event) { create(:classification_event) }
    let!(:diff_workflow_event) { create(:classification_with_diff_workflow) }
    let!(:diff_project_event) { create(:classification_with_diff_project) }
    let!(:diff_time_event) { create(:classification_created_yesterday) }
    let!(:diff_user_classification) { create(:classification_with_diff_user) }

    before(:each) do
      params[:id] = classification_event.user_id.to_s
    end

    it_behaves_like 'is filterable by workflow'
    it_behaves_like 'is filterable by project'
    it_behaves_like 'is filterable by date range'

    it 'filters by given user_id' do
      counts = count_user_classifications.call(params)
      expect(counts.to_sql).to include(".\"user_id\" = #{classification_event.user_id}")
    end

    it 'returns classification counts of given user' do
      counts = count_user_classifications.call(params)
      # because default is bucket by year and all data created in the same year, we expect counts to look something like
      # [<UserClassificationCounts::DailyUserClassificationCount period: 01-01-2023, count: 4>]
      current_year = Date.today.year
      expect(counts.length).to eq(1)
      expect(counts[0].count).to eq(4)
      expect(counts[0].period).to eq("01-01-#{current_year}")
    end

    it 'returns counts bucketed by given period' do
      params[:period] = 'day'
      counts = count_user_classifications.call(params)
      expect(counts.length).to eq(2)
      expect(counts[0].count).to eq(1)
      expect(counts[0].period).to eq((Date.today - 1).to_s)
      expect(counts[1].count).to eq(3)
      expect(counts[1].period).to eq(Date.today.to_s)
    end

    it 'returns counts of events with given workflow' do
      workflow_id = diff_workflow_event.workflow_id
      params[:workflow_id] = workflow_id.to_s
      counts = count_user_classifications.call(params)
      expect(counts.length).to eq(1)
      expect(counts[0].count).to eq(1)
    end

    it 'returns counts of events with given project' do
      project_id = diff_project_event.project_id
      params[:project_id] = project_id.to_s
      counts = count_user_classifications.call(params)
      expect(counts.length).to eq(1)
      expect(counts[0].count).to eq(1)
    end

    it 'returns counts of events within given date range' do
      last_week = Date.today - 7
      yesterday = Date.today - 1
      params[:start_date] = last_week.to_s
      params[:end_date] = yesterday.to_s
      counts = count_user_classifications.call(params)
      expect(counts.length).to eq(1)
      expect(counts[0].count).to eq(1)
    end
  end
end
