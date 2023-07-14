# frozen_string_literal: true

class UserClassificationCountsSerializer
  attr_reader :user_classification_counts

  def initialize(counts_scope)
    @user_classification_counts = counts_scope
  end

  def as_json(options)
    serializer_options = options[:serializer_options]
    period = serializer_options[:period]
    show_time_spent = serializer_options[:show_time_spent]
    num_top_projects_to_show = serializer_options[:top_project_contributions]
    total_count = user_classification_counts.sum(&:count).to_i
    total_time_spent = user_classification_counts.sum(&:session_time).to_f if show_time_spent

    response = { total_count: }
    response[:time_spent] = total_time_spent if show_time_spent
    show_proj_contributions(response, num_top_projects_to_show) if num_top_projects_to_show
    response[:data] = user_classification_counts if period
    response
  end

  private

  def show_proj_contributions(response, num_top_projects_to_show)
    response[:unique_projects_contributions] = unique_projects_count
    response[:top_project_contributions] = top_project_contributions(num_top_projects_to_show)
  end

  def unique_projects_count
    @user_classification_counts.map(&:project_id).uniq.count
  end

  def top_project_contributions(num_top_projects)
    project_contributions = {}
    @user_classification_counts.each do |c|
      if project_contributions[c.project_id]
        project_contributions[c.project_id] += c.count
      else
        project_contributions[c.project_id]  = c.count
      end
    end
    project_contributions.map { |k, v| { project_id: k, count: v } }.sort_by { |p| p[:count] }.reverse.first(num_top_projects)
  end
end
