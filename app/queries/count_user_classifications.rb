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
      include_today_to_scoped(scoped_upto_yesterday, params)
    else
      filter_by_date_range(scoped, params[:start_date], params[:end_date])
    end
  end

  private

  def current_date_classifications(params)
    current_date_hourly_classifications = hourly_relation(params).select(current_date_select_clause(params))
                                                                 .group(group_by_clause(params))
                                                                 .order('period')
                                                                 .where('hour >= ?', Date.today.to_s)

    current_date_hourly_classifications = filter_by_user_id(current_date_hourly_classifications, params[:id])
    current_date_hourly_classifications = filter_by_workflow_id(current_date_hourly_classifications, params[:workflow_id])
    filter_by_project_id(current_date_hourly_classifications, params[:project_id])
  end

  def include_today_to_scoped(scoped_upto_yesterday, params)
    period = (params[:period] || 'year').downcase
    todays_classifications = current_date_classifications(params)

    return scoped_upto_yesterday if todays_classifications.blank?

    if scoped_upto_yesterday.blank?
      todays_classifications.each do |classification|
        classification.period = start_of_current_period(period).to_time.utc
      end
      return todays_classifications
    end

    most_recent_date_from_scoped = scoped_upto_yesterday[-1].period.to_date

    if today_part_of_recent_period?(most_recent_date_from_scoped, period)
      add_todays_counts_to_recent_period_counts(scoped_upto_yesterday, todays_classifications, params)
    else
      todays_classifications.each do |classification|
        classification.period = start_of_current_period(period).to_time.utc
      end
      append_today_to_scoped(scoped_upto_yesterday, todays_classifications)
    end
  end

  def add_todays_counts_to_recent_period_counts(
    count_records_up_to_yesterday,
    todays_count,
    params
  )
    return add_project_contribution_counts(count_records_up_to_yesterday, todays_count, params[:time_spent]) if params[:project_contributions]

    current_period_counts =
      count_records_up_to_yesterday.last.count + todays_count[0].count
    count_records_up_to_yesterday.last.count = current_period_counts
    if params[:time_spent]
      current_period_times = count_records_up_to_yesterday.last.session_time + todays_count[0].session_time
      count_records_up_to_yesterday.last.session_time = current_period_times
    end
    count_records_up_to_yesterday
  end

  def add_project_contribution_counts(scoped, todays_counts, time_spent)
    scoped = scoped.to_a
    classifications_by_project = scoped.index_by(&:project_id)
    todays_counts.each do |today_count|
      existing_count = classifications_by_project[today_count.project_id]
      if existing_count
        existing_count.count += today_count.count
        existing_count.session_time += today_count.session_time if time_spent
      else
        scoped = scoped << today_count
      end
    end

    scoped
  end

  def initial_scope(relation, params)
    relation.select(select_clause(params)).group(group_by_clause(params)).order('period')
  end

  def group_by_clause(params)
    params[:project_contributions] ? 'period, project_id' : 'period'
  end

  def current_date_select_clause(params)
    select_clause = "time_bucket('1 day', hour) AS period, SUM(classification_count)::integer AS count"
    select_clause += optional_select_fields(params)
    select_clause
  end

  def select_clause(params)
    period = params[:period]
    clause = select_and_time_bucket_by(period, 'classification')
    clause += optional_select_fields(params)
    clause
  end

  def optional_select_fields(params)
    fields = ''
    fields += ', SUM(total_session_time)::float AS session_time' if params[:time_spent]
    fields += ', project_id' if params[:project_contributions]
    fields
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
