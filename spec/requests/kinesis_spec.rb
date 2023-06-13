# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Kinesis', type: :request do
  it 'processes the stream events' do
    comment_payload = File.read(Rails.root.join('spec/fixtures/example_kinesis_comment_payload.json'))
    classification_payload = File.read(Rails.root.join('spec/fixtures/example_kinesis_classification_payload.json'))
    post '/kinesis', headers: { 'CONTENT_TYPE' => 'application/json' },
                     params: "{\"payload\": [#{comment_payload}, #{classification_payload}]}"
    expect(response.status).to eq(204)
    expect(CommentEvent.count).to eq(1)
    expect(ClassificationEvent.count).to eq(1)
    expect(ClassificationUserGroup.count).to eq(2)
  end
end
