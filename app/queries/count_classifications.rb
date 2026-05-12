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

    # Querying the DailyClassificationCounts directly for Real Time Data is not performant if cagg is a Real Time Aggregate
    # Because we are limited in resources, we do the following mitigation:
    # 1. Create a New Hourly(Workflow/Project)ClassificationCount which is RealTime
    # and Create a Data Retention for this new aggregate (this should limit the amount of data the query planner has to sift through)
    # 2. Turn off Real Time aggregation for the Daily(Workflow/Project)ClassificationCount
    # 3. For classification count queries that include the current date's counts,
    # we query current date's counts via the Hourly(Project/Workflow)ClassificationCount
    # and query the Daily(Workflow/Project)Count for everything before the current date's

    if end_date_includes_today?(params[:end_date])
      scoped_upto_yesterday = filter_by_date_range(scoped, params[:start_date], Date.yesterday.to_s)
      scoped = include_today_to_scoped(scoped_upto_yesterday, params)
    else
      scoped = filter_by_date_range(scoped, params[:start_date], params[:end_date])
    end
    scoped
  end

  private

  def initial_scope(relation, period)
    relation.select(select_and_time_bucket_by(period, 'classification')).group('period').order('period')
  end

  def include_today_to_scoped(scoped_upto_yesterday, params)
    period = (params[:period] || 'year').downcase
    todays_classifications = current_date_classifications(params)
    return scoped_upto_yesterday if todays_classifications.blank?

    if scoped_upto_yesterday.blank?
      # Append a new entry using the start of the current period.
      # This occurs when the project is newly created and no existing period entry exists.
      todays_classifications[0].period = start_of_current_period(period).to_time.utc
      return todays_classifications
    end

    most_recent_date_from_scoped = scoped_upto_yesterday[-1].period.to_date

    # For weekly, monthly, and yearly periods, the current date may already
    # belong to the latest period returned from the database.
    #
    # If the current date falls within that period, add its count to the
    # existing entry. Otherwise, append a new entry for the current period.
    if today_part_of_recent_period?(most_recent_date_from_scoped, period)
      add_todays_counts_to_recent_period_counts(scoped_upto_yesterday, todays_classifications)
    else
      todays_classifications[0].period = start_of_current_period(period).to_time.utc
      append_today_to_scoped(scoped_upto_yesterday, todays_classifications)
    end
  end

  def start_of_current_period(period)
    today = Date.today
    case period
    when 'day'
      today
    when 'week'
      # Returns Monday of current week
      today.at_beginning_of_week
    when 'month'
      today.at_beginning_of_month
    when 'year'
      today.at_beginning_of_year
    end
  end

  def today_part_of_recent_period?(most_recent_date, period)
    most_recent_date == start_of_current_period(period)
  end

  def append_today_to_scoped(count_records_up_to_yesterday, todays_count)
    count_records_up_to_yesterday + todays_count
  end

  def add_todays_counts_to_recent_period_counts(count_records_up_to_yesterday, todays_count)
    current_period_counts = count_records_up_to_yesterday[-1].count + todays_count[0].count
    count_records_up_to_yesterday[-1].count = current_period_counts
    count_records_up_to_yesterday
  end

  def current_date_classifications(params)
    current_day_str = Date.today.to_s
    hourly_relation = hourly_relation(params)
    current_date_hourly_classifications = hourly_relation.select("time_bucket('1 day', hour) AS period, SUM(classification_count)::integer AS count").group('period').order('period').where("hour >= '#{current_day_str}'")
    current_date_hourly_classifications = filter_by_workflow_id(current_date_hourly_classifications, params[:workflow_id])
    filter_by_project_id(current_date_hourly_classifications, params[:project_id])
  end

  def end_date_includes_today?(end_date)
    includes_today = true
    includes_today = Date.parse(end_date) >= Date.today if end_date.present?
    includes_today
  end

  def hourly_relation(params)
    if params[:workflow_id]
      ClassificationCounts::HourlyWorkflowClassificationCount
    elsif params[:project_id]
      ClassificationCounts::HourlyProjectClassificationCount
    else
      ClassificationCounts::HourlyClassificationCount
    end
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
