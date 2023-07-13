# frozen_string_literal: true

class UserClassificationCountsSerializer
  attr_reader :user_classification_counts

  def initialize(counts_scope)
    @user_classification_counts = counts_scope
  end

  def as_json(options)
    serializer_options = options[:serializer_options]
    period = serializer_options[:period]
    show_time_spent = serializer_options[:show_time_spent]
    total_count = user_classification_counts.sum(&:count).to_i
    total_time_spent = user_classification_counts.sum(&:session_time).to_i

    response = { total_count: }
    response[time_spent] = total_time_spent if show_time_spent
    response[data] = user_classification_counts if period

  end
end
