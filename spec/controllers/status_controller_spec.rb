# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StatusController do
  describe '#show' do
    test_commit_id = 'test_commit_id-123'
    Rails.application.commit_id = test_commit_id

    it 'returns with http success' do
      get :show
      expect(response).to have_http_status(:ok)
    end

    it 'displays application status' do
      get :show
      expected_body = { revision: test_commit_id }.to_json
      expect(response.body).to eq(expected_body)
    end
  end
end
