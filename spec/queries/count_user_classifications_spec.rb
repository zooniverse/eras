# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CountUserClassifications do
  let(:params) { {} }
  let(:count_user_classifications) { described_class.new(params) }
  describe 'relation' do
    it 'returns DailyUserClassificationCount if not given workflow, project ids or project_contributions' do
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

    it 'returns DailyUserProjectClassificationCount if querying project_contributions' do
      params[:project_contributions] = true
      expect(count_user_classifications.counts.model).to be UserClassificationCounts::DailyUserProjectClassificationCount
    end
  end

  describe 'select_clause' do
    it 'buckets counts by year by default' do
      counts = count_user_classifications.call(params)
      expected_select_query = "SELECT time_bucket('1 year', day) AS period, SUM(classification_count)::integer AS count"
      expect(counts.to_sql).to include(expected_select_query)
    end

    it 'buckets counts by given period' do
      params[:period] = 'week'
      counts = count_user_classifications.call(params)
      expected_select_query = "SELECT time_bucket('1 week', day) AS period, SUM(classification_count)::integer AS count"
      expect(counts.to_sql).to include(expected_select_query)
    end

    it 'queries for total session time if querying for time_spent' do
      params[:time_spent] = true
      counts = count_user_classifications.call(params)
      expected_select_query = "SELECT time_bucket('1 year', day) AS period, SUM(classification_count)::integer AS count, SUM(total_session_time)::float AS session_time"
      expect(counts.to_sql).to include(expected_select_query)
    end

    it 'queries for project_id if querying for project_contributions' do
      params[:project_contributions] = true
      counts = count_user_classifications.call(params)
      expected_select_query = "SELECT time_bucket('1 year', day) AS period, SUM(classification_count)::integer AS count, project_id"
      expect(counts.to_sql).to include(expected_select_query)
    end
  end

  describe '#call' do
    let(:today) { Date.new(2026, 10, 2) }
    let!(:classification_event) { create(:classification_event, event_time: today) }
    let!(:diff_workflow_event) { create(:classification_with_diff_workflow, event_time: today) }
    let!(:diff_project_event) { create(:classification_with_diff_project, event_time: today) }
    let!(:diff_time_event) { create(:classification_event, classification_id: 3, event_time: today.advance(weeks: -1)) }
    let!(:diff_user_classification) { create(:classification_with_diff_user, event_time: today) }

    before(:each) do
      params[:id] = classification_event.user_id.to_s
      travel_to(today)
    end

    after do
      travel_back
    end

    it 'filters by given user_id' do
      counts = count_user_classifications.call(params)
      expect(counts.to_sql).to include(".\"user_id\" = #{classification_event.user_id}")
    end

    it 'returns classification counts of given user' do
      counts = count_user_classifications.call(params)
      # because default is bucket by year and all data created in the same year, we expect counts to look something like
      # [<UserClassificationCounts::DailyUserClassificationCount period: 01-01-2023, count: 4>]
      today.year
      expect(counts.length).to eq(1)
      expect(counts[0].count).to eq(4)
      expect(counts[0].period).to eq(today.beginning_of_year.to_time.utc)
    end

    it 'returns counts bucketed by given period' do
      params[:period] = 'day'
      counts = count_user_classifications.call(params)
      expect(counts.length).to eq(2)
      counts_by_period = counts.index_by(&:period)
      expect(counts_by_period[diff_time_event.event_time].count).to eq(1)
      expect(counts_by_period[classification_event.event_time].count).to eq(3)
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
      last_week = today - 7
      yesterday = today - 1
      params[:start_date] = last_week.to_s
      params[:end_date] = yesterday.to_s
      counts = count_user_classifications.call(params)
      expect(counts.length).to eq(1)
      expect(counts[0].count).to eq(1)
    end

    context 'querying using hierarchal continuous aggregates' do
      context 'when end_date EXCLUDES today' do
        context 'when applying filters' do
          before(:each) do
            params[:end_date] = (today - 1).to_s
          end
          it_behaves_like 'is filterable by workflow'
          it_behaves_like 'is filterable by project'
        end

        it 'returns counts of events within given date range' do
          last_week = today - 7
          yesterday = today - 1
          params[:start_date] = last_week.to_s
          params[:end_date] = yesterday.to_s
          counts = count_user_classifications.call(params)
          expect(counts.length).to eq(1)
          expect(counts[0].count).to eq(1)
        end
      end

      context 'when end_date includes today' do
        context 'when there are no counts for today' do
          let!(:diff_time_event_of_other_user) { create(:classification_event, user_id: 3, classification_id: 8, event_time: today - 1) }
          before(:each) do
            params[:id] = diff_time_event_of_other_user.user_id.to_s
          end

          it 'returns counts queried from DailyUserClassificationCount relation for classifications upto and including yesterday' do
            counts = count_user_classifications.call(params)
            expect(counts.length).to eq(1)
            expect(counts[0].count).to eq(1)
            expect(counts.model).to be UserClassificationCounts::DailyUserClassificationCount
          end
        end

        context 'when there are counts for today' do
          context 'when there are no counts for previous days ONLY today' do
            it 'returns counts queried from HourlyUserClassificationCount relation for classifications of today with correct period' do
              params[:period] = 'month'
              params[:id] = diff_user_classification.user_id.to_s
              counts = count_user_classifications.call(params)
              expect(counts.length).to eq(1)
              expect(counts[0].count).to eq(1)
              expect(counts[0].period).to eq(today.beginning_of_month.to_time.utc)
            end
          end

          describe '#hourly_relation' do
            it "queries today's counts from HourlyUserClassificationCount relation if no workflow_id or project_id present" do
              params[:period] = 'day'
              counts = count_user_classifications.call(params)
              expect(counts.last).to be_an_instance_of UserClassificationCounts::HourlyUserClassificationCount
            end

            it "queries today's counts from HourlyWorkflowUserClassificationCount relation if workflow_id present" do
              params[:workflow_id] = diff_workflow_event.workflow_id.to_s
              counts = count_user_classifications.call(params)
              expect(counts.length).to eq(1)
              expect(counts[0].count).to eq(1)
              expect(counts[0]).to be_an_instance_of UserClassificationCounts::HourlyUserWorkflowClassificationCount
            end

            it "queries today's counts from HourlyProjectUserClassificationCount relation if project_id present" do
              params[:project_id] = diff_project_event.project_id.to_s
              counts = count_user_classifications.call(params)
              expect(counts.length).to eq(1)
              expect(counts[0].count).to eq(1)
              expect(counts[0]).to be_an_instance_of UserClassificationCounts::HourlyUserProjectClassificationCount
            end

            it "queries today's counts from HourlyProjectUserClassificationCount relation if project_contributions is true" do
              params[:project_contributions] = true
              counts = count_user_classifications.call(params)
              expect(counts.last).to be_an_instance_of UserClassificationCounts::HourlyUserProjectClassificationCount
            end
          end

          context 'when today is part of the most recent period' do
            it 'adds todays counts to the most recent period counts' do
              counts = count_user_classifications.call(params)
              expect(counts.length).to eq(1)
              expect(counts[0].count).to eq(4)
              expect(counts[0].period).to eq(today.beginning_of_year.to_time.utc)
            end

            it 'adds todays counts to the most recent period counts if workflow_id is present' do
              params[:workflow_id] = classification_event.workflow_id.to_s
              counts = count_user_classifications.call(params)
              expect(counts.length).to eq(1)
              expect(counts[0].count).to eq(3)
              expect(counts[0].period).to eq(today.beginning_of_year.to_time.utc)
            end

            it 'adds todays counts to the most recent period counts if project_id is present' do
              params[:project_id] = classification_event.project_id.to_s
              counts = count_user_classifications.call(params)
              expect(counts.length).to eq(1)
              expect(counts[0].count).to eq(3)
              expect(counts[0].period).to eq(today.beginning_of_year.to_time.utc)
            end

            it 'adds session_time to the most recent period counts if time_spent is true' do
              params[:time_spent] = true
              counts = count_user_classifications.call(params)
              expect(counts.length).to eq(1)
              expect(counts[0].count).to eq(4)
              expected_session_time = classification_event.session_time + diff_time_event.session_time +
                                      diff_workflow_event.session_time +
                                      diff_project_event.session_time
              expect(counts[0].session_time).to eq(expected_session_time)
              expect(counts[0].period).to eq(today.beginning_of_year.to_time.utc)
            end

            it 'adds todays counts to the most recent period counts for EACH project if project_contributions is true' do
              params[:project_contributions] = true
              counts = count_user_classifications.call(params)
              expect(counts.length).to eq(2)

              counts_by_project = counts.index_by(&:project_id)
              first_project_counts = counts_by_project[classification_event.project_id]
              expect(first_project_counts.count).to eq(3)
              expect(first_project_counts.period).to eq(today.beginning_of_year.to_time.utc)

              second_project_counts = counts_by_project[diff_project_event.project_id]
              expect(second_project_counts.count).to eq(1)
              expect(second_project_counts.period).to eq(today.beginning_of_year.to_time.utc)
            end

            it 'adds session_time to the most recent period counts for EACH project if project_contributions is true and time_spent is true' do
              params[:project_contributions] = true
              params[:time_spent] = true
              counts = count_user_classifications.call(params)

              counts_by_project = counts.index_by(&:project_id)
              expected_session_time_first_project = classification_event.session_time + diff_time_event.session_time + diff_workflow_event.session_time
              expect(counts_by_project[classification_event.project_id].session_time).to eq(expected_session_time_first_project)

              expected_session_time_second_project = diff_project_event.session_time
              expect(counts_by_project[diff_project_event.project_id].session_time).to eq(expected_session_time_second_project)
            end
          end

          context 'when today is NOT part of the most recent period' do
            before do
              params[:period] = 'month'
            end

            it 'appends todays counts as a new period' do
              counts = count_user_classifications.call(params)
              # expect:
              # [
              # <UserClassificationCounts::DailyUserClassificationCount period: 10-01-2026, count: 1>
              # FROM diff_time_event,
              # <UserClassificationCounts::HourlyUserClassificationCount period: 11-01-2026, count: 3>
              # FROM classification_event, diff_proj_event and diff_workflow_event,
              # ]
              expect(counts.length).to eq(2)
              counts_by_period = counts.index_by(&:period)
              expect(counts_by_period[diff_time_event.event_time.beginning_of_month.to_time.utc].count).to eq(1)
              expect(counts_by_period[classification_event.event_time.beginning_of_month.to_time.utc].count).to eq(3)
            end

            it 'includes correct session_time for each bucket if time_spent is true' do
              params[:time_spent] = true
              counts = count_user_classifications.call(params)
              counts_by_period = counts.index_by(&:period)
              expect(counts_by_period[diff_time_event.event_time.beginning_of_month.to_time.utc].session_time).to eq(diff_time_event.session_time)

              expected_session_time = classification_event.session_time + diff_workflow_event.session_time +
                                      diff_project_event.session_time
              expect(counts_by_period[classification_event.event_time.beginning_of_month.to_time.utc].session_time).to eq(expected_session_time)
            end

            it 'appends todays counts as a new period if project_contributions is true' do
              params[:project_contributions] = true
              counts = count_user_classifications.call(params)
              # [<UserClassificationCounts::DailyUserProjectClassificationCount period: 10-01-2026, count: 1, project_id: 1> FROM diff_time_event,
              # <UserClassificationCounts::HourlyUserProjectClassificationCount period: 11-01-2026, count: 2, project_id: 1> FROM classification_event and diff_workflow_event,
              # <UserClassificationCounts::HourlyUserProjectClassificationCount period: 11-01-2026, count: 1, project_id: 2> FROM diff_project_event]
              expect(counts.length).to eq(3)
              counts_by_period_and_project = counts.index_by { |c| [c.period, c.project_id] }

              expect(counts_by_period_and_project[[diff_time_event.event_time.beginning_of_month.to_time.utc, diff_time_event.project_id]].count).to eq(1)

              expect(counts_by_period_and_project[[classification_event.event_time.beginning_of_month.to_time.utc, classification_event.project_id]].count).to eq(2)

              expect(counts_by_period_and_project[[diff_project_event.event_time.beginning_of_month.to_time.utc, diff_project_event.project_id]].count).to eq(1)
            end

            it 'includes correct session_time for each bucket if project_contributions is true and time_spent is true' do
              params[:project_contributions] = true
              params[:time_spent] = true
              counts = count_user_classifications.call(params)
              counts_by_period_and_project = counts.index_by { |c| [c.period, c.project_id] }

              diff_time_event_project_id_idx = [diff_time_event.event_time.beginning_of_month.to_time.utc, diff_time_event.project_id]
              expect(counts_by_period_and_project[diff_time_event_project_id_idx].session_time).to eq(diff_time_event.session_time)

              expected_session_time_first_project = classification_event.session_time + diff_workflow_event.session_time
              classification_event_time_and_project_id_idx = [classification_event.event_time.beginning_of_month.to_time.utc, classification_event.project_id]
              expect(counts_by_period_and_project[classification_event_time_and_project_id_idx].session_time).to eq(expected_session_time_first_project)

              expected_session_time_second_project = diff_project_event.session_time
              diff_project_event_time_and_project_id_idx = [diff_project_event.event_time.beginning_of_month.to_time.utc, diff_project_event.project_id]
              expect(counts_by_period_and_project[diff_project_event_time_and_project_id_idx].session_time).to eq(expected_session_time_second_project)
            end
          end
        end
      end
    end
  end
end
