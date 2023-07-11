# frozen_string_literal: true

class CountComments
  include Filterable
  include Selectable
  attr_reader :counts

  def initialize(params)
    @counts = initial_scope(relation(params), params[:period])
  end

  def call(params={})
    scoped = @counts
    scoped = filter_by_project_id(scoped, params[:project_id])
    scoped = filter_by_user_id(scoped, params[:user_id])
    filter_by_date_range(scoped, params[:start_date], params[:end_date])
  end

  private

  def initial_scope(relation, period)
    relation.select(select_by(period, 'comment')).group('period').order('period')
  end

  def relation(params)
    if params[:project_id] || (params[:project_id] && params[:user_id])
      CommentCounts::DailyProjectUserCommentCount
    elsif params[:user_id]
      CommentCounts::DailyUserCommentCount
    else
      CommentCounts::DailyCommentCount
    end
  end
end
