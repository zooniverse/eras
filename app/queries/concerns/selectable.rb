# frozen_string_literal: true

module Selectable
  TIME_BUCKET_OPTIONS = {
    day: '1 day',
    week: '1 week',
    month: '1 month',
    year: '1 year'
  }.freeze

  # event_type either 'classification' or 'comment'
  def select_by(period, event_type)
    period = 'year' if period.nil?
    time_bucket = TIME_BUCKET_OPTIONS[period.to_sym]
    "time_bucket('#{time_bucket}', day) AS period, SUM(#{event_type}_count)::integer AS count"
  end
end
