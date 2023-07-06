# frozen_string_literal: true

RSpec.shared_context 'filterable context' do
  let(:params) { {} }
  let(:counts_query) { described_class.new(params) }
end

RSpec.shared_examples 'is filterable by project' do
  include_context 'filterable context'

  it 'filters_by_project_id if project_id given' do
    params[:project_id] = '2'
    counts = counts_query.call(params)
    expect(counts.to_sql).to include(".\"project_id\" = #{params[:project_id]}")
  end

  it 'does not filter by project_id if project id not given' do
    counts = counts_query.call(params)
    expect(counts.to_sql.downcase).not_to include(".\"project_id\" = #{params[:project_id]}")
  end

  it 'filters by project_ids ids if multiple project_ids given' do
    params[:project_id] = '2,3'
    counts = counts_query.call(params)
    expect(counts.to_sql.downcase).to include('."project_id" in (2, 3)')
  end
end

RSpec.shared_examples 'is filterable by workflow' do
  include_context 'filterable context'

  it 'filters by workflow id if workflow_id given' do
    params[:workflow_id] = '2'
    counts = counts_query.call(params)
    expect(counts.to_sql.downcase).to include(".\"workflow_id\" = #{params[:workflow_id]}")
  end

  it 'filters by workflow ids if multiple workflow_ids given' do
    params[:workflow_id] = '2,3'
    counts = counts_query.call(params)
    expect(counts.to_sql.downcase).to include('."workflow_id" in (2, 3)')
  end

  it 'does not filter by workflow_id if no workflow_id given' do
    counts = counts_query.call(params)
    expect(counts.to_sql.downcase).not_to include('.\"workflow_id\" = ')
  end
end

RSpec.shared_examples 'is filterable by date range' do
  include_context 'filterable context'

  it 'filters with date range if start or end date given' do
    params[:start_date] = (Date.today - 1).to_s
    params[:end_date] = Date.today.to_s
    counts = counts_query.call(params)
    expect(counts.to_sql.downcase).to include("day > '#{params[:start_date]}' and day < '#{params[:end_date]}'")
  end

  it 'filters only by start_date if no end_date' do
    params[:start_date] = (Date.today - 1).to_s
    counts = counts_query.call(params)
    expect(counts.to_sql.downcase).to include("day > '#{params[:start_date]}'")
    expect(counts.to_sql.downcase).not_to include('and day < ')
  end

  it 'filters only by end_date if no start_date' do
    params[:end_date] = Date.today.to_s
    counts = counts_query.call(params)
    expect(counts.to_sql.downcase).to include("day < '#{params[:end_date]}'")
    expect(counts.to_sql.downcase).not_to include('day > ')
  end
end
