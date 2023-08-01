# frozen_string_literal: true

class CountGroupProjectContributions
  include Filterable
  attr_reader :counts

  def initialize
    @counts = initial_scope(relation)
  end

  def call(params={})
    scoped = @counts
    scoped = filter_by_user_group_id(scoped, params[:id])
    filter_by_date_range(scoped, params[:start_date], params[:end_date])
  end

  private

  def initial_scope(relation)
    relation.select(select_clause).group('project_id').order('count DESC')
  end

  def select_clause
    'project_id, SUM(classification_count)::integer AS count'
  end

  def relation
    UserGroupClassificationCounts::DailyGroupProjectClassificationCount
  end
end
