# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClassificationCountsSerializer do
  let(:classification_count) { build(:daily_classification_count) }
  let(:count_serializer) { described_class.new([classification_count]) }

  it 'returns total_count when period not given' do
    serialized = count_serializer.as_json(serializer_options: {})
    expect(serialized).to have_key(:total_count)
    expect(serialized).not_to have_key(:data)
    expect(serialized[:total_count]).to eq(classification_count.count)
  end

  it 'returns total_count and data when period is given' do
    serialized = count_serializer.as_json(serializer_options: { period: 'year' })
    expect(serialized).to have_key(:total_count)
    expect(serialized).to have_key(:data)
    expect(serialized[:data].size).to eq(1)
  end

  it 'sums up total_count correctly' do
    classification_count2 = build(:daily_classification_count)
    classification_counts = [classification_count, classification_count2]
    serializer = described_class.new(classification_counts)
    serialized = serializer.as_json(serializer_options: {})
    expect(serialized[:total_count]).to eq(classification_counts.sum(&:count))
  end
end
