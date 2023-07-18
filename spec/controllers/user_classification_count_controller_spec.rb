# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserClassificationCountController do
  describe 'GET query' do
    let!(:classification_event) { create(:classification_event) }
    # let!(:another_user_classification_event) { create(:classification_with_diff_user) }
    it 'returns total count of user classification events' do
      get :query, params: { id: classification_event.user_id }
      expected_response = { total_count: 1 }
      expect(response.status).to eq(200)
      expect(response.body).to eq(expected_response.to_json)
    end

    it 'returns total_count and breakdown of classificaton events when period given' do
      get :query, params: { id: classification_event.user_id, period: 'day' }
      expect(response.status).to eq(200)
      response_body = JSON.parse(response.body)
      expect(response_body['total_count']).to eq(1)
      expect(response_body['data'].length).to eq(1)
      expect(response_body['data'][0]['period']).to eq("#{Date.today}T00:00:00.000Z")
      expect(response_body['data'][0]['count']).to eq(1)
    end

    context 'param validations' do
      it_behaves_like 'ensure valid query params', :query, { id: 1 }
    end
  end
end
