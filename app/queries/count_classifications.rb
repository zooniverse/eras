# frozen_string_literal: true

class CountClassifications
  include Filterable
  include SelectableWithTimeBucket
  attr_reader :counts

  def initialize(params)
    @counts = initial_scope(relation(params), params[:period])
  end

  def call(params={})
    scoped = @counts
    scoped = filter_by_workflow_id(scoped, params[:workflow_id])
    scoped = filter_by_project_id(scoped, params[:project_id])
    if params[:workflow_id].present?
      if end_date_includes_today?(params[:end_date])
        scoped_upto_yesterday = filter_by_date_range(scoped, params[:start_date], Date.yesterday.to_s)
        scoped = include_today_to_scoped(scoped_upto_yesterday, params[:workflow_id], params[:period])
      else
        scoped = filter_by_date_range(scoped, params[:start_date], params[:end_date])
      end
    else
      scoped = filter_by_date_range(scoped, params[:start_date], params[:end_date])
    end
    return scoped
  end

  private

  def initial_scope(relation, period)
    relation.select(select_and_time_bucket_by(period, 'classification')).group('period').order('period')
  end

  def include_today_to_scoped(scoped_upto_yesterday, workflow_id, period)
    todays_classifications = current_date_workflow_classifications(workflow_id)
    most_recent_date_from_scoped = scoped_upto_yesterday[-1].period&.to_date
    most_recent_count = scoped_upto_yesterday[-1].count
    if is_today_part_of_recent_period?(most_recent_date_from_scoped, period)
      add_todays_counts_to_recent_period_counts(scoped_upto_yesterday, todays_classifications)
    else
      append_today_to_scoped(scoped_upto_yesterday, todays_classifications)
    end
  end

  def is_today_part_of_recent_period?(most_recent_date, period)
    case period
    when 'day'
      false
    when 'week'
      (Date.today - most_recent_date).to_i < 7
    when 'month'
      Date.today.month == most_recent_date.month
    when 'year'
      Date.today.year == most_recent_date.year
    end
  end

  def append_today_to_scoped(count_records_up_to_yesterday, todays_count)
    count_records_up_to_yesterday + todays_count
  end

  def add_todays_counts_to_recent_period_counts(count_records_up_to_yesterday, todays_counts
    current_period_counts = count_records_up_to_yesterday[-1].count + todays_count[0].count
    count_records_up_to_yesterday[-1].count = current_period_counts
    count_records_up_to_yesterday
  end

  def current_date_workflow_classifications(workflow_id)
    current_day_str = Date.today.to_s
    current_hourly_classifications = ClassificationCounts::HourlyWorkflowClassificationCount.select("time_bucket('1 day', hour) AS period, SUM(classification_count)::integer AS count").group('period').order('period').where("hour >= '#{current_day_str}'")
    filter_by_workflow_id(current_hourly_classifications, workflow_id)
  end

  # if period is day append today's result as a result
  # if period is week/month or year first check if today is in the week or month or year
  # if it is, add the count to the last count
  # if it isn't add a new entry to result

  def end_date_includes_today?(end_date)
    includes_today = true
    includes_today = Date.parse(end_date) >= Date.today if end_date.present?
    return includes_today
  end

  def relation(params)
    if params[:workflow_id]
      ClassificationCounts::DailyWorkflowClassificationCount
    elsif params[:project_id]
      ClassificationCounts::DailyProjectClassificationCount
    else
      ClassificationCounts::DailyClassificationCount
    end
  end
end
