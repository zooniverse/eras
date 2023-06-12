# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Kinesis', type: :request do
  it 'processes the stream events' do
    post '/kinesis', headers: { 'CONTENT_TYPE' => 'application/json' },
                     params: "{\"payload\": [#{File.read(Rails.root.join('spec/fixtures/example_kinesis_comment_payload.json'))}]}"
    expect(response.status).to eq(204)
    expect(CommentEvent.count).to eq(1)
  end
end
