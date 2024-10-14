# frozen_string_literal: true

class UserClassificationCountsSerializer
  attr_reader :user_classification_counts

  def initialize(counts_scope)
    @user_classification_counts = counts_scope
  end

  def as_json(options)
    serializer_options = options[:serializer_options]
    show_time_spent = serializer_options[:time_spent]
    show_project_contributions = serializer_options[:project_contributions]
    order_project_contributions_by = serializer_options[:order_project_contributions_by]

    total_count = user_classification_counts.sum(&:count).to_i
    response = { total_count: }
    calculate_time_spent(user_classification_counts, response) if show_time_spent
    response[:project_contributions] = project_contributions(order_project_contributions_by) if show_project_contributions
    response[:data] = response_data(user_classification_counts, show_project_contributions:, show_time_spent:) if serializer_options[:period]
    response
  end

  private

  def order_project_contributions_by_recents?(order_project_contributions_by)
    order_project_contributions_by && order_project_contributions_by.downcase == 'recents'
  end

  def calculate_time_spent(counts, response)
    total_time_spent = counts.sum(&:session_time).to_f
    response[:time_spent] = total_time_spent
  end

  def response_data(user_counts, show_project_contributions:, show_time_spent:)
    # when calculating top projects, our records returned from query will be counts (and session time) per user per project bucketed by time
    # eg.  { period: '01-01-2020', count: 38, project_id: 1 }, { period: '01-01-2020', count: 40, project_id: 2}
    # vs. Our desired response format which is counts (and session time) grouped by bucketed time. { period: '01-02-2020', count: 78 }
    if show_project_contributions
      counts_grouped_by_period = user_counts.group_by { |user_proj_class_count| user_proj_class_count[:period] }.transform_values do |counts_in_period|
        total_in_period = { count: counts_in_period.sum(&:count) }
        total_in_period_session_time = { session_time: counts_in_period.sum(&:session_time) } if show_time_spent
        show_time_spent ? total_in_period.merge(total_in_period_session_time) : total_in_period
      end
      counts_grouped_by_period.map { |period, totals| { period: }.merge(totals) }
    else
      user_counts.map do |c|
        period_data = {
          period: c.period,
          count: c.count
        }
        show_time_spent ? period_data.merge({ session_time: c.session_time }) : period_data
      end
    end
  end

  def project_contributions(order_by)
    project_contributions = @user_classification_counts.group_by(&:project_id).transform_values do |counts|
      counts.sum(&:count)
    end

    if order_project_contributions_by_recents?(order_by)
      period_to_contributed_project_ids = @user_classification_counts.sort_by { |ucc| ucc.period }.reverse.group_by(&:period).transform_values do |uccs|
        uccs.map { |ucc| ucc.project_id}
      end

      puts "MDY114 HITS HERE"
      puts period_to_contributed_project_ids.values.flatten.uniq
      recently_contributed_project_ids = period_to_contributed_project_ids.values.flatten.uniq
      recently_contributed_project_ids.map { |project_id| { project_id: , count: project_contributions[project_id] } }
    else
      project_contributions.map { |project_id, count| { project_id:, count: } }.sort_by { |proj_contribution| proj_contribution[:count] }.reverse
    end
  end
end
