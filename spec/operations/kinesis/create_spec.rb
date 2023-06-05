# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Kinesis::Create do
  describe 'comment_event creation' do
    let(:payload) { JSON.parse(File.read(Rails.root.join('spec/fixtures/example_kinesis_comment_payload.json'))) }
    let(:operation) { described_class.with_options({ payload: [payload] }) }

    it 'creates comment_event if payload is from talk' do
      expect { operation.run! }.to change(CommentEvent, :count).from(0).to(1)
      comment_event = CommentEvent.first
      payload_data = payload['data']
      expect(comment_event.comment_id).to eq(payload_data['id'].to_i)
      expect(comment_event.event_time).to eq(payload_data['created_at'])
      expect(comment_event.comment_updated_at).to eq(payload_data['updated_at'])
      expect(comment_event.project_id).to eq(payload_data['project_id'].to_i)
      expect(comment_event.user_id).to eq(payload_data['user_id'].to_i)
    end
  end

  describe 'classification_event creation' do
    let(:payload) do
      JSON.parse(File.read(Rails.root.join('spec/fixtures/example_kinesis_classification_payload.json')))
    end
    let(:operation) { described_class.with_options({ payload: [payload] }) }

    it 'creates classification_event if payload is from panoptes' do
      expect { operation.run! }.to change(ClassificationEvent, :count).from(0).to(1)
      classification_event =  ClassificationEvent.first
      payload_data = payload['data']
      expect(classification_event.classification_id).to eq(payload_data['id'].to_i)
      expect(classification_event.event_time).to eq(payload_data['created_at'])
      expect(classification_event.classification_updated_at).to eq(payload_data['updated_at'])
    end

    it 'sets the classification_event relation ids from payload links attribute' do
      operation.run!
      classification_event = ClassificationEvent.first
      payload_data = payload['data']
      payload_links = payload_data['links']
      expect(classification_event.project_id).to eq(payload_links['project'].to_i)
      expect(classification_event.workflow_id).to eq(payload_links['workflow'].to_i)
      expect(classification_event.user_id).to eq(payload_links['user'].to_i)
    end

    it 'sets the started_at and finished_at from metadata' do
      operation.run!
      classification_event = ClassificationEvent.first
      payload_data = payload['data']
      payload_metadata = payload_data['metadata']
      started_at = Time.parse(payload_metadata['started_at'])
      finished_at = Time.parse(payload_metadata['finished_at'])
      expect(classification_event.started_at).to eq(started_at)
      expect(classification_event.finished_at).to eq(finished_at)
    end

    it 'sets started_at time to nil if there is no started_at in metadata' do
      payload_data = payload['data']
      payload_metadata = payload_data['metadata']
      payload_metadata.delete('started_at')
      operation.run!
      classification_event = ClassificationEvent.first
      expect(classification_event.started_at).to eq(nil)
    end

    it 'sets finished_at to nil if there is no finished_at in metadata' do
      payload_data = payload['data']
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
        payload_data = payload['data']
        payload_metadata = payload_data['metadata']
        started_at = Time.parse(payload_metadata['started_at'])
        finished_at = Time.parse(payload_metadata['finished_at'])
        expect(classification_event.session_time).to eq(finished_at - started_at)
      end

      it 'caps session time if finished_at - started_at is over session limit' do
        payload_data = payload['data']
        payload_metadata = payload_data['metadata']
        started_at = Time.parse(payload_metadata['started_at'])
        finished_at = started_at + Kinesis::Create::SESSION_LIMIT + 1
        payload_metadata['finished_at'] = finished_at.strftime('%Y-%m-%dT%H:%M:%S%z')
        operation.run!
        classification_event = ClassificationEvent.first
        expect(classification_event.session_time).to eq(Kinesis::Create::SESSION_CAP)
      end

      it 'sets session time to 0 if finished_at - started_at is negative' do
        payload_data = payload['data']
        payload_metadata = payload_data['metadata']
        started_at = Time.parse(payload_metadata['started_at'])
        finished_at = started_at - 1
        payload_metadata['finished_at'] = finished_at.strftime('%Y-%m-%dT%H:%M:%S%z')
        operation.run!
        classification_event = ClassificationEvent.first
        expect(classification_event.session_time).to eq(0)
      end

      it 'sets session time to 0 if finished_at - started_at is nil' do
        payload_data = payload['data']
        payload_metadata = payload_data['metadata']
        payload_metadata.delete('started_at')
        payload_metadata.delete('finished_at')
        operation.run!
        classification_event = ClassificationEvent.first
        expect(classification_event.session_time).to eq(0)
      end
    end

    context 'classifying user belongs multiple user groups' do
      it 'creates classification_user_groups for every user_group user belongs to' do
        expect { operation.run! }.to change(ClassificationUserGroup, :count).from(0).to(2)
        payload_data = payload['data']
        payload_metadata = payload_data['metadata']
        classification_user_groups = ClassificationUserGroup.all
        classification_user_groups.each do |cug|
          expect(cug.classification_id).to eq(payload_data['id'].to_i)
          expect(cug.user_group_id.in?(payload_metadata['user_group_ids'])).to be true
        end
      end

      it 'sets classification_event user_group_ids from metadata' do
        operation.run!
        payload_data = payload['data']
        payload_metadata = payload_data['metadata']
        classification_event = ClassificationEvent.first
        expect(classification_event.user_group_ids).to eq(payload_metadata['user_group_ids'])
      end
    end

    context 'non-logged in user classification' do
      before(:each) do
        payload_data = payload['data']
        payload_links = payload_data['links']
        payload_metadata = payload_data['metadata']
        payload_links['user'] = nil
        payload_metadata.delete('selected_user_group_id')
        payload_metadata['user_group_ids'] = []
        operation.run!
      end

      it 'does not create classification_user_group' do
        expect(ClassificationUserGroup.count).to eq(0)
      end

      it 'creates classification_event without user_id and empty groups' do
        classification_event = ClassificationEvent.first
        expect(classification_event.user_id).to be_nil
        expect(classification_event.user_group_ids).to be_empty
      end
    end
  end
end
