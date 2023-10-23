# frozen_string_literal: true

require 'rails_helper'

RSpec.describe KinesisStream do
  let(:kinesis_stream) { described_class.new }
  let(:comment_payload) do
    JSON.parse(File.read(Rails.root.join('spec/fixtures/example_kinesis_comment_payload.json')))
  end
  let(:classification_payload) do
    JSON.parse(File.read(Rails.root.join('spec/fixtures/example_kinesis_classification_payload.json')))
  end

  describe 'receive' do
    it 'processes each item in the payload' do
      expect(StreamEvents).to receive(:from).with(comment_payload).ordered.and_return(double(process: true))
      expect(StreamEvents).to receive(:from).with(classification_payload).ordered.and_return(double(process: true))
      kinesis_stream.receive([comment_payload, classification_payload])
    end
    context 'payload has a comment' do
      it 'adds to comment_events array' do
        kinesis_stream.receive([comment_payload])
        expect(kinesis_stream.instance_variable_get(:@comment_events).length).to eq(1)
      end
    end

    context 'payload has classification' do
      it 'adds to classification_events array ' do
        kinesis_stream.receive([classification_payload])
        expect(kinesis_stream.instance_variable_get(:@classification_events).length).to eq(1)
      end

      it 'adds to classification_user_groups array if classifying user belongs to multiple user groups' do
        kinesis_stream.receive([classification_payload])
        expect(kinesis_stream.instance_variable_get(:@classification_user_groups).length).to eq(2)
      end

      it 'does not add to classification_user_groups if classification done by non-logged in user' do
        links = classification_payload['data']['links']
        links['user'] = nil
        kinesis_stream.receive([classification_payload])
        expect(kinesis_stream.instance_variable_get(:@classification_user_groups).length).to be_zero
      end
    end
  end

  describe 'create_events' do
    context 'payload has comments' do
      it 'creates comment_events' do
        expect { kinesis_stream.create_events([comment_payload]) }.to change(CommentEvent, :count).from(0).to(1)
      end
    end

    context 'payload has classifications' do
      it 'creates classification_event' do
        expect do
          kinesis_stream.create_events([classification_payload])
        end.to change(ClassificationEvent, :count).from(0).to(1)
      end

      it 'creates classification_user_groups if classifying user belongs to multiple user groups' do
        expect do
          kinesis_stream.create_events([classification_payload])
        end.to change(ClassificationUserGroup, :count).from(0).to(2)
      end

      it 'creates one classification_user_group per each user_group and disregards duplicates on user_group_ids' do
        classification_payload['data']['metadata']['user_group_ids'] = [1234, 1234]
        expect do
          kinesis_stream.create_events([classification_payload])
        end.to change(ClassificationUserGroup, :count).from(0).to(1)
      end
    end
  end
end
