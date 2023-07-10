# frozen_string_literal: true

class ClassificationCountsSerializer
  attr_reader :classification_counts

  def initialize(counts_scope)
    @classification_counts = counts_scope
  end

  def as_json(options)
    serializer_options = options[:serializer_options]
    period = serializer_options[:period]
    total_count = classification_counts.sum(&:count).to_i

    if period
      {
        total_count:,
        data: classification_counts
      }
    else
      { total_count: }
    end
  end
end
