# frozen_string_literal: true

RSpec.shared_examples 'returns 403 when authorization header is invalid' do
  it 'returns a 403 missing authorization header' do
    expected_response = { error: 'Missing Authorization header' }
    expect(response.status).to eq(403)
    expect(response.body).to eq(expected_response.to_json)
  end

  it 'returns a 403 missing authorization header' do
    request.headers['Authorization'] = 'asjdhaskdhsa'
    expected_response = { error: 'Missing Authorization header' }
    expect(response.status).to eq(403)
    expect(response.body).to eq(expected_response.to_json)
  end
end
