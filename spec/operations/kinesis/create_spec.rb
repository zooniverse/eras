# frozen_string_literal: true

require "rails_helper" 

RSpec.describe Kinesis::Create do
  context 'comment_event creation' do
    let(:payload) { JSON.parse(File.read(Rails.root.join('spec/fixtures/example_kinesis_comment_payload.json'))) }
    let(:operation) { described_class.with_options(payload) }

    it 'creates comment_event' do
      expect { operation.run! }.to change(CommentEvent, :count).from(0).to(1)
      comment_event = CommentEvent.first
      payload_data = payload['payload'][0]['data']
      expect(comment_event.comment_id).to eq(payload_data['id'])
      expect(comment_event.event_time).to eq(payload_data['created_at'])
      expect(comment_event.comment_updated_at).to eq(payload_data['updated_at'])
      expect(comment_event.project_id).to eq(payload_data['project_id'])
      expect(comment_event.user_id).to eq(payload_data['user_id'].to_i)
    end
  end
end
