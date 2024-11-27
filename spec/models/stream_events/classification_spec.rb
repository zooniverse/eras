# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StreamEvents::Classification do
  let(:classification_payload) do
    JSON.parse(File.read(Rails.root.join('spec/fixtures/example_kinesis_classification_payload.json')))
  end

  let(:data) { classification_payload.fetch('data') }
  let(:links) { data.fetch('links') }
  let(:classification_class) { described_class.new(classification_payload) }

  describe 'process' do
    it 'preps the classification hash' do
      prepared_payload = classification_class.process
      expect(prepared_payload[:classification_id]).to eq(data.fetch('id'))
      expect(prepared_payload[:event_time]).to eq(data.fetch('created_at'))
      expect(prepared_payload[:started_at]).to eq(StreamEvents.started_at(data))
      expect(prepared_payload[:finished_at]).to eq(StreamEvents.finished_at(data))
      expect(prepared_payload[:project_id]).to eq(links.fetch('project'))
      expect(prepared_payload[:workflow_id]).to eq(links.fetch('workflow'))
      expect(prepared_payload[:user_id]).to eq(links.fetch('user'))
      expect(prepared_payload[:user_group_ids]).to eq(data.fetch('metadata').fetch('user_group_ids'))
      expect(prepared_payload[:session_time]).to eq(StreamEvents.session_time(data))
      expect(prepared_payload[:already_seen]).to eq(StreamEvents.already_seen(data))
    end

    it 'sets the user_id to nil if no user in stream payload' do
      links.delete('user')
      prepared_payload = classification_class.process
      expect(prepared_payload[:user_id]).to be_nil
    end

    it 'sets user_group_ids to [] if user_group_ids not in metadata' do
      data.fetch('metadata').delete('user_group_ids')
      prepared_payload = classification_class.process
      expect(prepared_payload[:user_group_ids]).to eq([])
    end
  end
end
