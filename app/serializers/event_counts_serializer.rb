# frozen_string_literal: true

class EventCountsSerializer
  attr_reader :event_counts

  def initialize(counts_scope)
    @event_counts = counts_scope
  end

  def as_json(options)
    serializer_options = options[:serializer_options]
    period = serializer_options[:period]
    total_count = event_counts.sum(&:count).to_i

    if period
      {
        total_count:,
        data: event_counts
      }
    else
      { total_count: }
    end
  end
end
