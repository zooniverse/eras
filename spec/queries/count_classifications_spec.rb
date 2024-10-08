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
    let(:counts) { count_classifications.call(params) }
    it 'buckets counts by year by default' do
      expected_select_query = "SELECT time_bucket('1 year', day) AS period, SUM(classification_count)::integer AS count FROM \"daily_classification_count\" GROUP BY period ORDER BY period"
      expect(counts.to_sql).to eq(expected_select_query)
    end

    it 'buckets counts by given period' do
      params[:period] = 'week'
      expected_select_query = "SELECT time_bucket('1 week', day) AS period, SUM(classification_count)::integer AS count FROM \"daily_classification_count\" GROUP BY period ORDER BY period"
      expect(counts.to_sql).to eq(expected_select_query)
    end
  end

  describe '#call' do
    let!(:classification_event) { create(:classification_event) }
    let!(:diff_workflow_event) { create(:classification_with_diff_workflow) }
    let!(:diff_project_event) { create(:classification_with_diff_project) }
    let!(:diff_time_event) { create(:classification_created_yesterday) }
    let(:counts) { count_classifications.call(params) }

    it_behaves_like 'is filterable by workflow'
    it_behaves_like 'is filterable by project'
    it_behaves_like 'is filterable by date range'

    it 'returns counts of all events when no params given' do
      # because default is bucket by year and all data created in the same year, we expect counts to look something like
      # [<ClassificationCounts::DailyClassificationCount period: 01-01-2023, count: 4>]
      current_year = Date.today.year
      expect(counts.length).to eq(1)
      expect(counts[0].count).to eq(4)
      expect(counts[0].period).to eq("01-01-#{current_year}")
    end

    it 'returns counts bucketed by given period' do
      params[:period] = 'day'
      expect(counts.length).to eq(2)
      expect(counts[0].count).to eq(1)
      expect(counts[0].period).to eq((Date.today - 1).to_s)
      expect(counts[1].count).to eq(3)
      expect(counts[1].period).to eq(Date.today.to_s)
    end

    it 'returns counts of events with given workflow' do
      workflow_id = diff_workflow_event.workflow_id
      params[:workflow_id] = workflow_id.to_s
      expect(counts.length).to eq(1)
      expect(counts[0].count).to eq(1)
    end

    it 'returns counts of events with given project' do
      project_id = diff_project_event.project_id
      params[:project_id] = project_id.to_s
      expect(counts.length).to eq(1)
      expect(counts[0].count).to eq(1)
    end

    it 'returns counts of events within given date range' do
      last_week = Date.today - 7
      yesterday = Date.today - 1
      params[:start_date] = last_week.to_s
      params[:end_date] = yesterday.to_s
      expect(counts.length).to eq(1)
      expect(counts[0].count).to eq(1)
    end

    context 'when params[:workflow_id] present' do
      context 'when params[:end_date] is before current date' do
        it 'returns counts from DailyWorkflowClassificationCount' do
          yesterday = Date.today - 1
          params[:workflow_id] = diff_time_event.workflow_id.to_s
          params[:end_date] = yesterday.to_s
          expect(counts.model).to be(ClassificationCounts::DailyWorkflowClassificationCount)
          expect(counts.length).to eq(1)
          expect(counts[0].count).to eq(1)
        end
      end

      context 'when params[:end_date] includes current date' do
        before do
          params[:end_date] = Date.today.to_s
        end

        context 'when 0 classifications up to previous day' do
          context 'when 0 classifications for current day' do
            it 'returns from DailyWorkflowClassificationCount' do
              # Select a workflow id that has no classification
              params[:workflow_id] = '100'
              expect(counts.model).to be(ClassificationCounts::DailyWorkflowClassificationCount)
              expect(counts.length).to eq(0)
            end
          end

          context 'when there are classifications for current day' do
            before do
              params[:workflow_id] = diff_workflow_event.workflow_id.to_s
            end

            it "returns today's classifications from HourlyWorkflowClassificationCount" do
              expect(counts.model).to be(ClassificationCounts::HourlyWorkflowClassificationCount)
              expect(counts.length).to eq(1)
              expect(counts[0].count).to eq(1)
            end

            it 'returns current date when period is day' do
              params[:period] = 'day'
              expect(counts[0].period).to eq(Date.today.to_time.utc)
            end

            it 'returns start of week when period is week' do
              params[:period] = 'week'
              expect(counts[0].period).to eq(Date.today.at_beginning_of_week.to_time.utc)
            end

            it 'returns start of month when period is month' do
              params[:period] = 'month'
              expect(counts[0].period).to eq(Date.today.at_beginning_of_month.to_time.utc)
            end

            it 'returns start of year when period is year' do
              params[:period] = 'year'
              expect(counts[0].period).to eq(Date.today.at_beginning_of_year.to_time.utc)
            end
          end
        end

        context 'when there are classifications up to previous day' do
          context 'when there are 0 classifications for current day' do
            let!(:classification_created_yesterday_diff_workflow) { create(:classification_created_yesterday, workflow_id: 4, classification_id: 100) }
            it 'returns from DailyWorkflowCount (scoped up to yesterday)' do
              params[:workflow_id] = classification_created_yesterday_diff_workflow.workflow_id.to_s
              expect(counts.model).to be(ClassificationCounts::DailyWorkflowClassificationCount)
              expect(counts.length).to eq(1)
              expect(counts[0].count).to eq(1)
            end
          end

          context 'when there are classifications for current day' do
            before do
              allow(Date).to receive(:today).and_return Date.new(2022, 10, 21)
              params[:workflow_id] = diff_workflow_event.workflow_id.to_s
              params[:period] = 'year'
            end

            context 'when current day is part of the most recently pulled period' do
              it 'adds the most recent period to the most recently pulled period counts' do
                create(:classification_with_diff_workflow, classification_id: 1000, event_time: Date.new(2022, 1, 2))
                expect(counts.length).to eq(1)
                # the 2 classifications counted is the one created in L170 as well as diff_workflow_event classification.
                expect(counts[0].count).to eq(2)
                expect(counts[0].period).to eq(Date.today.at_beginning_of_year)
              end
            end

            context 'when current day is not part of the most recently pulled period' do
              it 'appends a new entry to scoped from HourlyWorkflowCount query' do
                create(:classification_with_diff_workflow, classification_id: 1000, event_time: Date.new(2021, 1, 2))
                expect(counts.length).to eq(2)
                counts.each { |c| expect(c.count).to eq(1) }
                expect(counts[0].class).to be(ClassificationCounts::DailyWorkflowClassificationCount)
                expect(counts[1].class).to be(ClassificationCounts::HourlyWorkflowClassificationCount)
                expect(counts.last.period).to eq(Date.today.at_beginning_of_year)
              end
            end
          end
        end
      end
    end
  end
end
