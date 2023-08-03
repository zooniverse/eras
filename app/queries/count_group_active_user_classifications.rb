# frozen_string_literal: true

class CountGroupActiveUserClassifications
  include Filterable
  include SelectableWithTimeBucket
  attr_reader :counts

  def initialize(params)
    @counts = initial_scope(relation(params))
  end

  def call(params={})
    scoped = @counts
    scoped = filter_by_user_group_id(scoped, params[:id])
    scoped = filter_by_workflow_id(scoped, params[:workflow_id])
    scoped = filter_by_project_id(scoped, params[:project_id])
    filter_by_date_range(scoped, params[:start_date], params[:end_date])
  end

  private

  def initial_scope(relation)
    relation.select(select_clause).group('user_id').order('count DESC')
  end

  def select_clause
    'user_id, SUM(classification_count)::integer AS count'
  end

  def relation(params)
    if params[:project_id]
      UserGroupClassificationCounts::DailyGroupUserProjectClassificationCount
    elsif params[:workflow_id]
      UserGroupClassificationCounts::DailyGroupUserWorkflowClassificationCount
    else
      UserGroupClassificationCounts::DailyGroupUserClassificationCount
    end
  end
end
