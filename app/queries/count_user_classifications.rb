# frozen_string_literal: true

class CountUserClassifications
  include Filterable
  include SelectableWithTimeBucket
  include IncludesCurrentDay
  attr_reader :counts

  def initialize(params)
    @counts = initial_scope(relation(params), params)
  end

  def call(params={})
    scoped = @counts
    scoped = filter_by_user_id(scoped, params[:id])
    scoped = filter_by_workflow_id(scoped, params[:workflow_id])
    scoped = filter_by_project_id(scoped, params[:project_id])

    if end_date_includes_today?(params[:end_date])
      scoped_upto_yesterday = filter_by_date_range(scoped, params[:start_date], Date.yesterday.to_s)
      scoped = include_today_to_scoped(scoped_upto_yesterday, params)
    else
      scoped = filter_by_date_range(scoped, params[:start_date], params[:end_date])
    end
    scoped
  end

  private

  def current_date_classifications(params)
    current_day_str = Date.today.to_s
    hourly_relation = hourly_relation(params)
    select_clause = "time_bucket('1 day', hour) AS period, SUM(classification_count)::integer AS count"
    select_clause += ', SUM(total_session_time)::float AS session_time' if params[:time_spent]
    select_clause += ', project_id' if params[:project_contributions]
    current_date_hourly_classifications = hourly_relation.select(select_clause).group('period').order('period').where("hour >= '#{current_day_str}'")
    current_date_hourly_classifications = current_date_hourly_classifications.group('project_id') if params[:project_contributions]
    current_date_hourly_classifications = filter_by_user_id(current_date_hourly_classifications, params[:id])
    current_date_hourly_classifications = filter_by_workflow_id(current_date_hourly_classifications, params[:workflow_id])
    current_date_hourly_classifications = filter_by_project_id(current_date_hourly_classifications, params[:project_id])
    current_date_hourly_classifications
  end

  def include_today_to_scoped(scoped_upto_yesterday, params)
    period = (params[:period] || 'year').downcase
    todays_classifications = current_date_classifications(params)
    return scoped_upto_yesterday if todays_classifications.blank?

    if scoped_upto_yesterday.blank?
      # Append a new entry using the start of the current period.
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
      add_todays_times_to_recent_period_times(scoped_upto_yesterday, todays_classifications) if params[:time_spent]
    else
      todays_classifications[0].period = start_of_current_period(period).to_time.utc
      append_today_to_scoped(scoped_upto_yesterday, todays_classifications)
    end
  end

  def add_todays_times_to_recent_period_times(count_records_up_to_yesterday, todays_count)
    current_period_times = count_records_up_to_yesterday[-1].session_time + todays_count[0].session_time
    count_records_up_to_yesterday[-1].session_time = current_period_times
    count_records_up_to_yesterday
  end

  def initial_scope(relation, params)
    relation.select(select_clause(params)).group(group_by_clause(params)).order('period')
  end

  def group_by_clause(params)
    params[:project_contributions] ? 'period, project_id' : 'period'
  end

  def select_clause(params)
    period = params[:period]
    clause = select_and_time_bucket_by(period, 'classification')
    clause += ', SUM(total_session_time)::float AS session_time' if params[:time_spent]
    clause += ', project_id' if params[:project_contributions]
    clause
  end

  def hourly_relation(params)
    if params[:workflow_id]
      UserClassificationCounts::HourlyUserWorkflowClassificationCount
    elsif params[:project_id] || params[:project_contributions]
      UserClassificationCounts::HourlyUserProjectClassificationCount
    else
      UserClassificationCounts::HourlyUserClassificationCount
    end
  end

  def relation(params)
    if params[:project_id] || params[:project_contributions]
      UserClassificationCounts::DailyUserProjectClassificationCount
    elsif params[:workflow_id]
      UserClassificationCounts::DailyUserWorkflowClassificationCount
    else
      UserClassificationCounts::DailyUserClassificationCount
    end
  end
end
