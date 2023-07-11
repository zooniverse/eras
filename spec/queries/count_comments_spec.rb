# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CountComments do
  let(:params) { {} }
  let(:count_comments) { described_class.new(params) }
  describe 'relation' do
    it 'returns DailyCommentCount if not any params' do
      expect(count_comments.counts.model).to be CommentCounts::DailyCommentCount
    end

    it 'returns DailyProjectUserCommentCount if project_id given' do
      params[:project_id] = 2
      expect(count_comments.counts.model).to be CommentCounts::DailyProjectUserCommentCount
    end

    it 'returns DailyProjectUserCommentCount if project_id and user_id given' do
      params[:project_id] = 2
      params[:user_id] = 2
      expect(count_comments.counts.model).to be CommentCounts::DailyProjectUserCommentCount
    end

    it 'returns DailyUserCommentCount if user_id but not project_id given' do
      params[:user_id] = 2
      expect(count_comments.counts.model).to be CommentCounts::DailyUserCommentCount
    end
  end

  describe 'select_by' do
    it 'buckets counts by year by default' do
      counts = count_comments.call(params)
      expected_select_query = "SELECT time_bucket('1 year', day) AS period, SUM(comment_count)::integer AS count FROM \"daily_comment_count\" GROUP BY period ORDER BY period"
      expect(counts.to_sql).to eq(expected_select_query)
    end

    it 'buckets counts by given period' do
      params[:period] = 'week'
      counts = count_comments.call(params)
      expected_select_query = "SELECT time_bucket('1 week', day) AS period, SUM(comment_count)::integer AS count FROM \"daily_comment_count\" GROUP BY period ORDER BY period"
      expect(counts.to_sql).to eq(expected_select_query)
    end
  end

  describe '#call' do
    let!(:comment_event) { create(:comment_event) }
    let!(:diff_project_comment) { create(:comment_with_project) }
    let!(:diff_time_event) { create(:comment_created_yesterday) }
    let!(:diff_user_comment) { create(:comment_with_diff_user) }

    it_behaves_like 'is filterable by project'
    it_behaves_like 'is filterable by date range'

    it 'filters by user_id if user_id given' do
      params[:user_id] = '3'
      counts = count_comments.call(params)
      expect(counts.to_sql).to include(".\"user_id\" = #{params[:user_id]}")
    end

    it 'filters by user_ids if multiple user_ids given' do
      params[:user_id] = '3,4'
      counts = count_comments.call(params)
      expect(counts.to_sql.downcase).to include('."user_id" in (3, 4)')
    end

    it 'does not filter by user_id if user_id not given' do
      counts = count_comments.call(params)
      expect(counts.to_sql.downcase).not_to include('."user_id" = ')
    end

    it 'returns counts of all events when no params given' do
      counts = count_comments.call(params)
      # because default is bucket by year and all data created in the same year, we expect counts to look something like
      # [<CommentCounts::DailyCommentCount period: 01-01-2023, count: 4>]
      current_year = Date.today.year
      expect(counts.length).to eq(1)
      expect(counts[0].count).to eq(4)
      expect(counts[0].period).to eq("01-01-#{current_year}")
    end

    it 'returns counts bucketed by given period' do
      params[:period] = 'day'
      counts = count_comments.call(params)
      expect(counts.length).to eq(2)
      expect(counts[0].count).to eq(1)
      expect(counts[0].period).to eq((Date.today - 1).to_s)
      expect(counts[1].count).to eq(3)
      expect(counts[1].period).to eq(Date.today.to_s)
    end

    it 'returns counts of events with given project' do
      project_id = diff_project_comment.project_id
      params[:project_id] = project_id.to_s
      counts = count_comments.call(params)
      expect(counts.length).to eq(1)
      expect(counts[0].count).to eq(1)
    end

    it 'returns counts of comments with given user' do
      user_id = diff_user_comment.user_id
      params[:user_id] = user_id.to_s
      counts = count_comments.call(params)
      expect(counts.length).to eq(1)
      expect(counts[0].count).to eq(1)
    end

    it 'returns counts of events within given date range' do
      last_week = Date.today - 7
      yesterday = Date.today - 1
      params[:start_date] = last_week.to_s
      params[:end_date] = yesterday.to_s
      counts = count_comments.call(params)
      expect(counts.length).to eq(1)
      expect(counts[0].count).to eq(1)
    end
  end
end
