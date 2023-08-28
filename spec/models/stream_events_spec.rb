# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StreamEvents do
  describe 'comment event' do
    let(:comment_payload) do
      JSON.parse(File.read(Rails.root.join('spec/fixtures/example_kinesis_comment_payload.json')))
    end

    it 'checks that payload is a comment event' do
      expect(StreamEvents.comment_event?(comment_payload)).to be true
    end

    it 'checks that payload is not a classification' do
      expect(StreamEvents.classification_event?(comment_payload)).to be false
    end

    it 'returns a StreamEvents::Comment class from payload' do
      expect(StreamEvents.from(comment_payload)).to be_a StreamEvents::Comment
    end
  end

  describe 'classification event' do
    let(:classification_payload) do
      JSON.parse(File.read(Rails.root.join('spec/fixtures/example_kinesis_classification_payload.json')))
    end
    let(:event_data) { classification_payload['data'] }
    let(:event_metadata) { event_data['metadata'] }

    it 'checks that payload is a classification' do
      expect(StreamEvents.classification_event?(classification_payload)).to be true
    end

    it 'returns a StreamEvents::Classification class from payload' do
      expect(StreamEvents.from(classification_payload)).to be_a StreamEvents::Classification
    end

    it 'returns started_at from the metadata' do
      expected_started_at = Time.parse(event_metadata['started_at'])
      expect(StreamEvents.started_at(event_data)).to eq(expected_started_at)
    end

    it 'returns finished_at from the metadata' do
      expected_finished_at = Time.parse(event_metadata['finished_at'])
      expect(StreamEvents.finished_at(event_data)).to eq(expected_finished_at)
    end

    it 'returns started_at to nil if no started_at in metadata' do
      event_metadata.delete('started_at')
      expect(StreamEvents.started_at(event_data)).to be_nil
    end

    it 'returns finished_at to nil if no finished_at in metadata' do
      event_metadata.delete('finished_at')
      expect(StreamEvents.finished_at(event_data)).to be_nil
    end

    context 'user_group_ids?' do
      it 'returns true if classification done by user that belongs to multiple user groups' do
        expect(StreamEvents.user_group_ids?(event_data)).to be true
      end

      it 'returns false if classification done by non-logged in user' do
        links = event_data['links']
        links['user'] = nil

        expect(StreamEvents.user_group_ids?(event_data)).to be false
      end

      it 'returns false if user_group_ids in payload metadata is []' do
        event_metadata['user_group_ids'] = []
        expect(StreamEvents.user_group_ids?(event_data)).to be false
      end
    end

    context 'session_time calculation' do
      it 'sets session_time to finished_at - started_at if within session limit' do
        started_at = Time.parse(event_metadata['started_at'])
        finished_at = Time.parse(event_metadata['finished_at'])
        expect(StreamEvents.session_time(event_data)).to eq(finished_at - started_at)
      end

      it 'caps session_time if finished_at - started_at is over session limit' do
        started_at = Time.parse(event_metadata['started_at'])
        finished_at = started_at + StreamEvents::SESSION_LIMIT + 1
        event_metadata['finished_at'] = finished_at.strftime('%Y-%m-%dT%H:%M:%S%z')
        expect(StreamEvents.session_time(event_data)).to eq(StreamEvents::SESSION_CAP)
      end

      it 'returns session time as 0 if finished_at - started_at is negative' do
        started_at = Time.parse(event_metadata['started_at'])
        finished_at = started_at - 1
        event_metadata['finished_at'] = finished_at.strftime('%Y-%m-%dT%H:%M:%S%z')
        expect(StreamEvents.session_time(event_data)).to be_zero
      end

      it 'returns session time as 0 if finished_at - started_at is nil' do
        event_metadata.delete('started_at')
        expect(StreamEvents.session_time(event_data)).to be_zero
      end
    end
  end

  describe 'unknown event' do
    let(:event_payload) do
      { 'source' => 'panoptes',
        'type' => 'workflow_counters',
        'version' => '1.0.0',
        'timestamp' => '2023-08-28T19:26:28Z', 'data' => {},
        'linked' => {} }
    end

    it 'returns a StreamEvents::UnknownEvent class from payload' do
      expect(StreamEvents.from(event_payload)).to be_a StreamEvents::UnknownEvent
    end
  end
end
