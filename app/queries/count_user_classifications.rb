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
    scoped = filter_by_workflow_id(scoped, params[:workflow_id])
    scoped = filter_by_project_id(scoped, params[:project_id])
    scoped = filter_by_user_id(scoped, params[:id])
    filter_by_date_range(scoped, params[:start_date], params[:end_date])
  end

  private

  def initial_scope(relation, params)
    period = params[:period]
    select_clause = select_by(period, 'classification')
    select_clause += ', SUM(total_session_time) AS session_time' if params[:time_spent]
    select_clause += ', project_id' if params[:top_project_contributions]
    group_by = 'period'
    group_by += ', project_id' if params[:top_project_contributions]
    relation.select(select_clause).group(group_by).order('period')
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
