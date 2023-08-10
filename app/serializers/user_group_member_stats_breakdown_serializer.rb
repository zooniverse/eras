# frozen_string_literal: true

class UserGroupMemberStatsBreakdownSerializer
  attr_reader :group_member_classification_counts

  def initialize(counts_scope)
    @group_member_classification_counts = counts_scope
  end

  def as_json(_options)
    {
      group_member_stats_breakdown: counts_grouped_by_user
    }
  end

  private

  def counts_grouped_by_user
    counts_grouped_by_member = group_member_classification_counts.group_by { |member_proj_contribution| member_proj_contribution[:user_id] }.transform_values do |member_counts_per_project|
      total_per_member = { count: member_counts_per_project.sum(&:count) }
      total_per_member[:session_time] = member_counts_per_project.sum(&:session_time)
      total_per_member[:project_contributions] = individual_member_project_contributions(member_counts_per_project)
      total_per_member
    end
    counts_grouped_by_member.map { |user_id, totals| { user_id: }.merge(totals) }.sort_by(&:count)
  end

  def individual_member_project_contributions(member_counts_per_project)
    member_counts_per_project.sort_by(&:count).reverse.map { |member_count| member_count.as_json.except('user_id') }
  end
end
