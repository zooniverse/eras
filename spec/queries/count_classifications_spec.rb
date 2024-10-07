# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CountClassifications do
  let(:params) { {} }
  let(:count_classifications) { described_class.new(params) }
  describe 'relation' do
    it 'returns DailyClassificationCount if not given workflow or project ids' do
      expect(count_classifications.counts.model).to be ClassificationCounts::DailyClassificationCount
    end

    it 'returns DailyWorkflowClassificationCount if workflow_id given' do
      params[:workflow_id] = 2
      expect(count_classifications.counts.model).to be ClassificationCounts::DailyWorkflowClassificationCount
    end

    it 'returns DailyProjectClassificationCount if project_id given' do
      params[:project_id] = 2
      expect(count_classifications.counts.model).to be ClassificationCounts::DailyProjectClassificationCount
    end
  end

  describe 'select_and_time_bucket_by' do
    it 'buckets counts by year by default' do
      counts = count_classifications.call(params)
      expected_select_query = "SELECT time_bucket('1 year', day) AS period, SUM(classification_count)::integer AS count FROM \"daily_classification_count\" GROUP BY period ORDER BY period"
      expect(counts.to_sql).to eq(expected_select_query)
    end

    it 'buckets counts by given period' do
      params[:period] = 'week'
      counts = count_classifications.call(params)
      expected_select_query = "SELECT time_bucket('1 week', day) AS period, SUM(classification_count)::integer AS count FROM \"daily_classification_count\" GROUP BY period ORDER BY period"
      expect(counts.to_sql).to eq(expected_select_query)
    end
  end

  describe '#call' do
    let!(:classification_event) { create(:classification_event) }
    let!(:diff_workflow_event) { create(:classification_with_diff_workflow) }
    let!(:diff_project_event) { create(:classification_with_diff_project) }
    let!(:diff_time_event) { create(:classification_created_yesterday) }

    it_behaves_like 'is filterable by workflow'
    it_behaves_like 'is filterable by project'
    it_behaves_like 'is filterable by date range'

    it 'returns counts of all events when no params given' do
      counts = count_classifications.call(params)
      # because default is bucket by year and all data created in the same year, we expect counts to look something like
      # [<ClassificationCounts::DailyClassificationCount period: 01-01-2023, count: 4>]
      current_year = Date.today.year
      expect(counts.length).to eq(1)
      expect(counts[0].count).to eq(4)
      expect(counts[0].period).to eq("01-01-#{current_year}")
    end

    it 'returns counts bucketed by given period' do
      params[:period] = 'day'
      counts = count_classifications.call(params)
      expect(counts.length).to eq(2)
      expect(counts[0].count).to eq(1)
      expect(counts[0].period).to eq((Date.today - 1).to_s)
      expect(counts[1].count).to eq(3)
      expect(counts[1].period).to eq(Date.today.to_s)
    end

    it 'returns counts of events with given workflow' do
      workflow_id = diff_workflow_event.workflow_id
      params[:workflow_id] = workflow_id.to_s
      counts = count_classifications.call(params)
      expect(counts.length).to eq(1)
      expect(counts[0].count).to eq(1)
    end

    it 'returns counts of events with given project' do
      project_id = diff_project_event.project_id
      params[:project_id] = project_id.to_s
      counts = count_classifications.call(params)
      expect(counts.length).to eq(1)
      expect(counts[0].count).to eq(1)
    end

    it 'returns counts of events within given date range' do
      last_week = Date.today - 7
      yesterday = Date.today - 1
      params[:start_date] = last_week.to_s
      params[:end_date] = yesterday.to_s
      counts = count_classifications.call(params)
      expect(counts.length).to eq(1)
      expect(counts[0].count).to eq(1)
    end

    context 'when params[:workflow_id] present' do
      context 'when params[:end_date] is before current date' do
        it 'returns counts from DailyWorkflowClassificationCount'do
          yesterday = Date.today - 1
          params[:workflow_id] = diff_time_event.workflow_id.to_s
          params[:end_date] = yesterday.to_s
          counts = count_classifications.call(params)
          expect(counts.model).to be(ClassificationCounts::DailyWorkflowClassificationCount)
          expect(counts.length).to eq(1)
          expect(counts[0].count).to eq(1)
        end
      end

      context 'when params[:end_date] includes current date' do
        context 'when no classification count up to previous day' do
          context 'when no classifications for current day' do
            it 'returns from DailyWorkflowClassificationCount' do
              # Select a workflow id that has no classification
              params[:workflow_id] = '100'
              params[:end_date] = Date.today.to_s
              counts = count_classifications.call(params)
              expect(counts.model).to be(ClassificationCounts::DailyWorkflowClassificationCount)
              expect(counts.length).to eq(0)
            end
          end

          context 'when there are classifications for current day' do
            it 'returns from HourlyWorkflowCount' do
            end

            it 'returns proper start of period' do
            end
          end
        end

        context 'when there are classifications up to previous day' do
          context 'when there are no classifications for current day' do
            it 'returns from DailyWorkflowCount (scoped up to yesterday)' do
            end
          end

          context 'when there are classifications for current day' do
            context 'when current day is part of the most recently pulled period' do
              it 'adds the most recent period to the most recently pulled period counts' do
              end
            end

            context 'when current day is not part of the most recently pulled period' do
              it 'appends a new entry to scoped from HourlyWorkflowCount query' do
              end
            end
          end
        end
      end
    end
  end
end
