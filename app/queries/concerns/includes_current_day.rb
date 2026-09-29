# frozen_string_literal: true

module IncludesCurrentDay
  def today_part_of_recent_period?(most_recent_date, period)
    most_recent_date == start_of_current_period(period)
  end

  def start_of_current_period(period)
    today = Date.today

    case period
    when 'day'
      today
    when 'week'
      today.at_beginning_of_week
    when 'month'
      today.at_beginning_of_month
    when 'year'
      today.at_beginning_of_year
    end
  end

  def append_today_to_scoped(count_records_up_to_yesterday, todays_count)
    count_records_up_to_yesterday + todays_count
  end

  def add_todays_counts_to_recent_period_counts(
    count_records_up_to_yesterday,
    todays_count
  )
    current_period_counts =
      count_records_up_to_yesterday[-1].count + todays_count[0].count

    count_records_up_to_yesterday[-1].count = current_period_counts

    count_records_up_to_yesterday
  end

  def end_date_includes_today?(end_date)
    includes_today = true

    includes_today =
      Date.parse(end_date) >= Date.today if end_date.present?

    includes_today
  end
end