# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StreamEvents::ClassificationUserGroup do
  let(:classification_payload) do
    JSON.parse(File.read(Rails.root.join('spec/fixtures/example_kinesis_classification_payload.json')))
  end
  let(:data) { classification_payload.fetch('data') }
  let(:links) { data.fetch('links') }
  let(:user_group_id) { data.fetch('metadata').fetch('user_group_ids')[0] }
  let(:classification_user_group) { described_class.new(data, user_group_id) }

  it 'preps the classification_user_group hash' do
    prepared_payload = classification_user_group.process
    expect(prepared_payload[:classification_id]).to eq(data.fetch('id'))
    expect(prepared_payload[:event_time]).to eq(data.fetch('created_at'))
    expect(prepared_payload[:user_group_id]).to eq(user_group_id)
    expect(prepared_payload[:project_id]).to eq(links.fetch('project'))
    expect(prepared_payload[:workflow_id]).to eq(links.fetch('workflow'))
    expect(prepared_payload[:user_id]).to eq(links.fetch('user'))
  end
end
