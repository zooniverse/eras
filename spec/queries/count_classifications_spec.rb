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

    it 'returns DailyProjectClassificationCount if workflow_id given' do
      params[:project_id] = 2
      expect(count_classifications.counts.model).to be ClassificationCounts::DailyProjectClassificationCount
    end
  end

  describe 'select_clause' do
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
    it_behaves_like 'is filterable'
  end
end
