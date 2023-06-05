require 'rails_helper'

RSpec.describe KinesisController do
  describe "POST create" do
    it 'processes the stream events' do
      post :create, params: { payload: [JSON.load(File.read(Rails.root.join("spec/fixtures/example_kinesis_classification_payload.json")))] }, as: :json
      expect(response.status).to eq(204)
    end
  end
end