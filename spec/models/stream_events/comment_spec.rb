# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StreamEvents::Comment do
  let(:comment_payload) do
    JSON.parse(File.read(Rails.root.join('spec/fixtures/example_kinesis_comment_payload.json')))
  end
  let(:data) { comment_payload.fetch('data') }
  let(:comment) { described_class.new(comment_payload) }

  it 'preps comment_event hash from stream payload' do
    data['updated_at'] = Time.now
    prepared_payload = comment.process
    expect(prepared_payload[:comment_id]).to eq(data.fetch('id'))
    expect(prepared_payload[:event_time]).to eq(data.fetch('created_at'))
    expect(prepared_payload[:comment_updated_at]).to eq(data.fetch('updated_at'))
    expect(prepared_payload[:project_id]).to eq(data.fetch('project_id'))
    expect(prepared_payload[:user_id]).to eq(data.fetch('user_id'))
  end

  it 'sets comment_updated_at to nil if no updated_at in payload data' do
    prepared_payload = comment.process
    expect(prepared_payload[:comment_updated_at]).to eq(nil)
  end
end
