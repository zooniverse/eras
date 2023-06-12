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
end
