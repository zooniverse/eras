# frozen_string_literal: true

class UserClassificationCountsSerializer
  attr_reader :user_classification_counts

  def initialize(counts_scope)
    @user_classification_counts = counts_scope
  end

  def as_json(options)
    serializer_options = options[:serializer_options]
    show_time_spent = serializer_options[:show_time_spent]
    num_top_projects_to_show = serializer_options[:top_project_contributions]
    total_count = user_classification_counts.sum(&:count).to_i
    response = { total_count: }
    calculate_time_spent(user_classification_counts, response) if show_time_spent
    show_proj_contributions(response, num_top_projects_to_show) if num_top_projects_to_show
    response[:data] = response_data(user_classification_counts, num_top_projects_to_show, show_time_spent) if serializer_options[:period]
    response
  end

  private

  def calculate_time_spent(counts, response)
    total_time_spent = counts.sum(&:session_time).to_f
    response[:time_spent] = total_time_spent
  end

  def response_data(user_counts, num_top_projects, show_time_spent)
    # when calculating top projects, our records returned from query will be counts (and session time) per user per project bucketed by time
    # eg.  { period: '01-01-2020', count: 38, project_id: 1 }, { period: '01-01-2020', count: 40, project_id: 2}
    # vs. Our desired response format which is counts (and session time) grouped by bucketed time. { period: '01-02-2020', count: 78 }
    if num_top_projects
      counts_grouped_by_period = user_counts.group_by { |user_proj_class_count| user_proj_class_count[:period] }.transform_values do |counts_in_period|
        total_in_period = { count: counts_in_period.sum(&:count) }
        total_in_period[:session_time] = counts_in_period.sum(&:session_time) if show_time_spent
        total_in_period
      end
      counts_grouped_by_period.map { |period, totals| { period: }.merge(totals) }
    else
      user_counts
    end
  end

  def show_proj_contributions(response, num_top_projects_to_show)
    response[:unique_project_contributions] = unique_projects_count
    response[:top_project_contributions] = top_project_contributions(num_top_projects_to_show)
  end

  def unique_projects_count
    @user_classification_counts.map(&:project_id).uniq.count
  end

  def top_project_contributions(num_top_projects)
    project_contributions = @user_classification_counts.group_by(&:project_id).transform_values do |counts|
      counts.sum(&:count)
    end
    project_contributions.map { |project_id, count| { project_id:, count: } }.sort_by { |proj_contribution| proj_contribution[:count] }.reverse.first(num_top_projects)
  end
end
