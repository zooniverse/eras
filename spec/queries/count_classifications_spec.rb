# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CountClassifications do
  describe 'relation' do
    let(:params) { {} }
    let(:count_classifications) { described_class.new(params) }
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
end
