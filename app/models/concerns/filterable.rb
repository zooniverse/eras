# frozen_string_literal: true

module Filterable
  def filter_by_project_id(scoped, project_id)
    return scoped unless project_id.present?

    project_ids = project_id.split(',')
    scoped.where(project_id: project_ids)
  end

  def filter_by_workflow_id(scoped, workflow_id)
    return scoped unless workflow_id.present?

    workflow_ids = workflow_id.split(',')
    scoped.where(workflow_id: workflow_ids)
  end

  def filter_by_date_range(scoped, start_date, end_date)
    range_clause = range_clause(start_date, end_date)
    return scoped unless range_clause

    scoped.where(range_clause)
  end

  def filter_by_user_id(scoped, user_id)
    return scoped unless user_id.present?

    user_ids = user_id.split(',')
    scoped.where(user_id: user_ids)
  end

  private

  def range_clause(start_date, end_date)
    range_clause = ''
    range_clause += "day >= '#{start_date}'" if start_date
    range_clause += ' and ' if start_date && end_date
    range_clause += "day <= '#{end_date}'" if end_date
    range_clause
  end
end
