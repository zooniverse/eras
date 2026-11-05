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
    scoped = apply_filters(scoped, params)

    if end_date_includes_today?(params[:end_date])
      scoped_upto_yesterday = filter_by_date_range(scoped, params[:start_date], Date.yesterday.to_s)
      include_today_to_scoped(scoped_upto_yesterday, params)
    else
      filter_by_date_range(scoped, params[:start_date], params[:end_date])
    end
  end

  private

  def normalized_period(params)
    (params[:period] || 'year').downcase
  end

  def apply_filters(scoped, params)
    scoped = filter_by_user_id(scoped, params[:id])
    scoped = filter_by_workflow_id(scoped, params[:workflow_id])
    filter_by_project_id(scoped, params[:project_id])
  end

  def current_date_classifications(params)
    current_date_hourly_classifications = hourly_relation(params)
                                          .select(current_date_select_clause(params))
                                          .group(group_by_clause(params))
                                          .order('period')
                                          .where('hour >= ?', Date.today.to_s)
    apply_filters(current_date_hourly_classifications, params)
  end

  def append_todays_counts_as_new_period(scoped_upto_yesterday, todays_classifications, period)
    todays_classifications.each do |classification_count|
      classification_count.period = start_of_current_period(period).to_time.utc
    end
    append_today_to_scoped(scoped_upto_yesterday, todays_classifications)
  end

  def include_today_to_scoped(scoped_upto_yesterday, params)
    todays_classifications = current_date_classifications(params)
    return scoped_upto_yesterday if todays_classifications.blank?

    period = normalized_period(params)
    return append_todays_counts_as_new_period(scoped_upto_yesterday, todays_classifications, period) if scoped_upto_yesterday.blank?

    most_recent_date_from_scoped = scoped_upto_yesterday.last.period.to_date

    if today_part_of_recent_period?(most_recent_date_from_scoped, period)
      add_todays_counts_to_recent_period_counts(scoped_upto_yesterday, todays_classifications, params)
    else
      append_todays_counts_as_new_period(scoped_upto_yesterday, todays_classifications, period)
    end
  end

  def add_todays_counts_to_recent_period_counts(
    counts_up_to_yesterday,
    todays_count,
    params
  )
    return add_project_contribution_counts(counts_up_to_yesterday, todays_count, params) if params[:project_contributions]

    current_period_counts =
      counts_up_to_yesterday.last.count + todays_count[0].count
    counts_up_to_yesterday.last.count = current_period_counts
    if params[:time_spent]
      current_period_times = counts_up_to_yesterday.last.session_time + todays_count[0].session_time
      counts_up_to_yesterday.last.session_time = current_period_times
    end
    counts_up_to_yesterday
  end

  def add_project_contribution_counts(scoped, todays_counts, params)
    scoped = scoped.to_a
    period = normalized_period(params)
    classifications_by_project = scoped.index_by(&:project_id)
    todays_counts.each do |today_count|
      existing_count = classifications_by_project[today_count.project_id]
      if existing_count
        existing_count.count += today_count.count
        existing_count.session_time += today_count.session_time if params[:time_spent]
      else
        today_count.period = start_of_current_period(period).to_time.utc
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
    period = normalized_period(params)
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
