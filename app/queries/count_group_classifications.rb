# frozen_string_literal: true

class CountGroupClassifications
  include Filterable
  include Selectable
  attr_reader :counts

  def initialize(params)
    @counts = initial_scope(relation(params), params)
  end

  def call(params={})
    scoped = @counts
    scoped = filter_by_user_group_id(scoped, params[:id])
    scoped = filter_by_workflow_id(scoped, params[:workflow_id])
    scoped = filter_by_project_id(scoped, params[:project_id])
    filter_by_date_range(scoped, params[:start_date], params[:end_date])
  end

  private

  def initial_scope(relation, params)
    relation.select(select_clause(params)).group('period').order('period')
  end

  def select_clause(params)
    period = params[:period]
    clause = select_by(period, 'classification')
    clause += ', SUM(total_session_time)::float AS session_time'
    clause
  end

  def relation(params)
    if params[:project_id]
      UserGroupClassificationCounts::DailyGroupProjectClassificationCount
    elsif params[:workflow_id]
      UserGroupClassificationCounts::DailyGroupWorkflowClassificationCount
    else
      UserGroupClassificationCounts::DailyGroupClassificationCount
    end
  end
end
