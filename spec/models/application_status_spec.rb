# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationStatus do
  subject(:status) { described_class.new }

  it 'returns the commit_id' do
    Rails.application.commit_id = 'test_commit_id-123'
    expect(status.as_json).to eq({ revision: 'test_commit_id-123' })
  end
end
