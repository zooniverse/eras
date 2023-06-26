# frozen_string_literal: true

class CountClassifications
  include Filterable
  TIME_BUCKET_OPTIONS = {
    day: '1 day',
    week: '1 week',
    month: '1 month',
    year: '1 year'
  }.freeze
  attr_reader :counts

  def initialize(params)
    @counts = initial_scope(relation(params), params[:period])
  end

  def call(params={})
    scoped = counts
    scoped = filter_by_workflow_id(scoped, params[:workflow_id])
    scoped = filter_by_project_id(scoped, params[:project_id])
    filter_by_date_range(scoped, params[:start_date], params[:end_date])
  end

  private

  def initial_scope(relation, period)
    relation.select(select_clause(period)).group('period').order('period')
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

  def select_clause(period)
    period = 'year' if period.nil?
    time_bucket = TIME_BUCKET_OPTIONS[period.to_sym]
    "time_bucket('#{time_bucket}', day) AS period, SUM(classification_count)::integer AS count"
  end
end
