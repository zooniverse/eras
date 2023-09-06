# frozen_string_literal: true

class CountGroupMemberBreakdown
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
    relation.select(select_clause).group('user_id, project_id')
  end

  def select_clause
    'user_id, project_id, SUM(classification_count)::integer AS count, SUM(total_session_time)::float AS session_time'
  end

  def relation
    UserGroupClassificationCounts::DailyGroupUserProjectClassificationCount
  end
end
