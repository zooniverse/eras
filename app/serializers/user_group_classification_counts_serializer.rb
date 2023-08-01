# frozen_string_literal: true

class UserGroupClassificationCountsSerializer
  attr_reader :group_classification_counts, :active_user_counts, :project_contributions

  def initialize(group_counts_scope, user_counts_scope, project_counts_scope)
    @group_classification_counts = group_counts_scope
    @active_user_counts = user_counts_scope
    @project_contributions = project_counts_scope
  end

  def as_json(options)
    serializer_options = options[:serializer_options]
    total_count = group_classification_counts.sum(&:count).to_i
    time_spent = group_classification_counts.sum(&:session_time).to_f
    active_users = active_user_counts.length
    response = { total_count:, time_spent:, active_users: }
    response[:project_contributions] = project_contributions unless project_contributions.nil?
    response[:top_contributors] = top_contributors(serializer_options[:top_contributors]) if serializer_options[:top_contributors]
    response[:data] = group_classification_counts if serializer_options[:period]
    response
  end

  private

  def top_contributors(num_top_users_to_show)
    active_user_counts.first(num_top_users_to_show)
  end
end
