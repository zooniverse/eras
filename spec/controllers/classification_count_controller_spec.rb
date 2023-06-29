# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClassificationCountController do
  describe 'GET query' do
    let!(:classification_event) { create(:classification_event) }
    it 'returns total count of classification events' do
      get :query, params: {}
      expected_response = { total_count: 1 }
      expect(response.status).to eq(200)
      expect(response.body).to eq(expected_response.to_json)
    end

    it 'returns total_count and breakdown of classificaton events when period given' do
      get :query, params: { period: 'day' }
      expect(response.status).to eq(200)
      response_body = JSON.parse(response.body)
      expect(response_body['total_count']).to eq(1)
      expect(response_body['data'].length).to eq(1)
      expect(response_body['data'][0]['period']).to eq("#{Date.today}T00:00:00.000Z")
      expect(response_body['data'][0]['count']).to eq(1)
    end

    it_behaves_like 'ensure valid query params', :query
  end
end
