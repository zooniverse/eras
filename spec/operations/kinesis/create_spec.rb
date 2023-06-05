# frozen_string_literal: true

require "rails_helper" 

RSpec.describe Kinesis::Create do
  context 'payload has talk comment' do
    let(:payload) { JSON.parse(File.read(Rails.root.join('spec/fixtures/example_kinesis_comment_payload.json'))) }
    let(:operation) { described_class.with_options(payload) }

    it 'creates comment_event' do
      expect { operation.run! }.to change(CommentEvent, :count).from(0).to(1)
      comment_event = CommentEvent.first
      payload_data = payload['payload'][0]['data']
      expect(comment_event.comment_id).to eq(payload_data['id'].to_i)
      expect(comment_event.event_time).to eq(payload_data['created_at'])
      expect(comment_event.comment_updated_at).to eq(payload_data['updated_at'])
      expect(comment_event.project_id).to eq(payload_data['project_id'].to_i)
      expect(comment_event.user_id).to eq(payload_data['user_id'].to_i)
    end
  end

  context 'payload has classification' do
    let(:payload) { JSON.parse(File.read(Rails.root.join('spec/fixtures/example_kinesis_classification_payload.json'))) }
    let(:operation) { described_class.with_options(payload) }
    
    it 'creates classification_event' do
      expect { operation.run! }.to change(ClassificationEvent, :count).from(0).to(1)
      classification_event =  ClassificationEvent.first
      payload_data = payload['payload'][0]['data']
      expect(classification_event.classification_id).to eq(payload_data['id'].to_i)
      expect(classification_event.event_time).to eq(payload_data['created_at'])
      expect(classification_event.classification_updated_at).to eq(payload_data['updated_at'])
    end

    it 'sets the classification_event relation ids from payload links attribute' do
      operation.run!
      classification_event = ClassificationEvent.first
      payload_data = payload['payload'][0]['data']
      payload_links = payload_data['links']
      expect(classification_event.project_id).to eq(payload_links['project'].to_i)
      expect(classification_event.workflow_id).to eq(payload_links['workflow'].to_i)
      expect(classification_event.user_id).to eq(payload_links['user'].to_i)
    end

    it 'sets the started_at and finished_at from metadata' do
      operation.run!
      classification_event = ClassificationEvent.first
      payload_data = payload['payload'][0]['data']
      payload_metadata = payload_data['metadata']
      started_at = Time.parse(payload_metadata['started_at'])
      finished_at = Time.parse(payload_metadata['finished_at'])
      expect(classification_event.started_at).to eq(started_at)
      expect(classification_event.finished_at).to eq(finished_at)
    end

    it 'sets started_at time to nil if there is no started_at in metadata' do
      payload_data = payload['payload'][0]['data']
      payload_metadata = payload_data['metadata']
      payload_metadata.delete('started_at')
      operation.run!
      classification_event = ClassificationEvent.first
      expect(classification_event.started_at).to eq(nil)
    end

    it 'sets finished_at to nil if there is no finished_at in metadata' do
      payload_data = payload['payload'][0]['data']
      payload_metadata = payload_data['metadata']
      payload_metadata.delete('finished_at')
      operation.run!
      classification_event = ClassificationEvent.first
      expect(classification_event.finished_at).to eq(nil)
    end

    context 'session_time calculation' do
      it 'sets session time to finished_at - started_at if within session limit' do
        operation.run!
        classification_event = ClassificationEvent.first
        payload_data = payload['payload'][0]['data']
        payload_metadata = payload_data['metadata']
        started_at = Time.parse(payload_metadata['started_at'])
        finished_at = Time.parse(payload_metadata['finished_at'])
        expect(classification_event.session_time).to eq(finished_at - started_at)
      end

      it 'caps session time if finished_at - started_at is over session limit' do
        payload_data = payload['payload'][0]['data']
        payload_metadata = payload_data['metadata']
        started_at = Time.parse(payload_metadata['started_at'])
        finished_at = started_at + Kinesis::Create::SESSION_LIMIT + 1
        payload_metadata['finished_at'] = finished_at.strftime('%Y-%m-%dT%H:%M:%S%z')
        operation.run!
        classification_event = ClassificationEvent.first
        expect(classification_event.session_time).to eq(Kinesis::Create::SESSION_CAP)
      end

      it 'sets session time to 0 if finished_at - started_at is negative' do
      end

      it 'sets session time to 0 if finished_at - started_at is nil' do
      end
    end

    context 'classification made by user who belong to multiple user groups' do
      it 'creates classification_user_group' do
      end
    end

    context 'non-logged in user classification' do
    end
  end
end
