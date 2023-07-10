# frozen_string_literal: true

RSpec.shared_examples 'ensure valid query params' do |query|
  let(:params) { {} }

  it 'validates date range given' do
    params[:start_date] = Date.today
    params[:end_date] = (Date.today - 1).to_s
    get query, params: params
    expect(response.status).to eq(400)
    expect(response.body).to include('Date range entered is not valid')
  end

  it 'validates period bucket' do
    params[:period] = 'hour'
    get query, params: params
    expect(response.status).to eq(400)
    expect(response.body).to include('Invalid bucket option. Valid options for period is day, week, month, or year')
  end

  it 'ensures that we do not query by both workflow and project' do
    params[:workflow_id] = 1
    params[:project_id] = 2
    get query, params: params
    expect(response.status).to eq(400)
    expect(response.body).to include('Cannot query by workflow and project. Either query by one or the other')
  end

  it 'validates date given' do
    params[:start_date] = '2020-01-32'
    get query, params: params
    expect(response.status).to eq(400)
    expect(response.body).to include('Invalid date')
  end
end
