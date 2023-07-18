# frozen_string_literal: true

class CountUserClassifications
  include Filterable
  include Selectable
  attr_reader :counts

  def initialize(params)
    @counts = initial_scope(relation(params), params)
  end

  def call(params={})
    scoped = @counts
    scoped = filter_by_user_id(scoped, params[:id])
    scoped = filter_by_workflow_id(scoped, params[:workflow_id])
    scoped = filter_by_project_id(scoped, params[:project_id])
    filter_by_date_range(scoped, params[:start_date], params[:end_date])
  end

  private

  def initial_scope(relation, params)
    relation.select(select_clause(params)).group(group_by_clause(params)).order('period')
  end

  def group_by_clause(params)
    params[:top_project_contributions] ? 'period, project_id' : 'period'
  end

  def select_clause(params)
    period = params[:period]
    clause = select_by(period, 'classification')
    clause += ', SUM(total_session_time)::float AS session_time' if params[:time_spent]
    clause += ', project_id' if params[:top_project_contributions]
    clause
  end

  def relation(params)
    if params[:project_id] || params[:top_project_contributions]
      UserClassificationCounts::DailyUserProjectClassificationCount
    elsif params[:workflow_id]
      UserClassificationCounts::DailyUserWorkflowClassificationCount
    else
      UserClassificationCounts::DailyUserClassificationCount
    end
  end
end
