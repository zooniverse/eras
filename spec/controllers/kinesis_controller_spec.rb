# frozen_string_literal: true

require 'rails_helper'

RSpec.describe KinesisController do
  def http_login(username=Rails.application.credentials.kinesis_username,
                 password=Rails.application.credentials.kinesis_password)
    @env ||= {}
    @env["HTTP_AUTHORIZATION"] = ActionController::HttpAuthentication::Basic.encode_credentials(username, password)
    @env
  end

  describe 'POST create' do
    before(:each) do
      allow(Rails.application.credentials).to receive(:kinesis_username).and_return('kinesis_username')
      allow(Rails.application.credentials).to receive(:kinesis_password).and_return('kinesis_password')
    end

    it 'processes the stream events' do
      request.headers.merge!(http_login)
      post :create,
            params: { payload: [JSON.parse(File.read(Rails.root.join('spec/fixtures/example_kinesis_classification_payload.json')))] }, as: :json
      expect(response.status).to eq(204)
    end

    it 'should require HTTP Basic authentication' do
      request.headers.merge!(http_login('wrong', 'incorrect'))
      post :create,
            params: { payload: [JSON.parse(File.read(Rails.root.join('spec/fixtures/example_kinesis_classification_payload.json')))] }, as: :json
      expect(response.status).to eq(403)
    end
  end
end
