# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Kinesis', type: :request do
  it 'processes the stream events' do
    allow(Rails.application.credentials).to receive(:kinesis_username).and_return('test_basic_auth')
    allow(Rails.application.credentials).to receive(:kinesis_password).and_return('test_basic_auth123')
    comment_payload = File.read(Rails.root.join('spec/fixtures/example_kinesis_comment_payload.json'))
    classification_payload = File.read(Rails.root.join('spec/fixtures/example_kinesis_classification_payload.json'))
    post '/kinesis', headers: { 'CONTENT_TYPE' => 'application/json' },
                     params: "{\"payload\": [#{comment_payload}, #{classification_payload}]}",
                     env: { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials('test_basic_auth', 'test_basic_auth123') }
    expect(response.status).to eq(204)
    expect(CommentEvent.count).to eq(1)
    expect(ClassificationEvent.count).to eq(1)
    expect(ClassificationUserGroup.count).to eq(2)
  end

  it 'requires HTTP Basic auth' do
    allow(Rails.application.credentials).to receive(:kinesis_username).and_return('test_basic_auth')
    allow(Rails.application.credentials).to receive(:kinesis_password).and_return('test_basic_auth123')
    post '/kinesis', headers: { 'CONTENT_TYPE' => 'application/json' },
                     params: '{"payload": []}',
                     env: { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials('wrong', 'incorrect') }
    expect(response.status).to eq(403)
  end

  it 'returns 403 forbidden when no credentials given in non-dev env' do
    allow(Rails.env).to receive(:development?).and_return(false)
    allow(Rails.env).to receive(:test?).and_return(false)
    post '/kinesis', headers: { 'CONTENT_TYPE' => 'application/json' },
                     params: '{"payload": []}'
    expect(response.status).to eq(403)
  end
end
