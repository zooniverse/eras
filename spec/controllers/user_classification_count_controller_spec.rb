# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserClassificationCountController do
  include AuthenticationHelpers

  describe 'GET query' do
    let!(:classification_event) { create(:classification_event) }

    context 'user querying their own stats' do
      before(:each) { authenticate!(classification_event.user_id) }

      it 'returns total count of user classification events' do
        get :query, params: { id: classification_event.user_id.to_s }
        expected_response = { total_count: 1 }
        expect(response.status).to eq(200)
        expect(response.body).to eq(expected_response.to_json)
      end

      it 'returns total_count and breakdown of user classifications when period given' do
        get :query, params: { id: classification_event.user_id, period: 'day' }
        expect(response.status).to eq(200)
        response_body = JSON.parse(response.body)
        expect(response_body['total_count']).to eq(1)
        expect(response_body['data'].length).to eq(1)
        expect(response_body['data'][0]['period']).to eq("#{Date.today}T00:00:00.000Z")
        expect(response_body['data'][0]['count']).to eq(1)
      end

      it 'returns total_count and time_spent and breakdown of user classifications where period is given' do
        get :query, params: { id: classification_event.user_id, period: 'day', time_spent: true }
        expect(response.status).to eq(200)
        response_body = JSON.parse(response.body)
        expect(response_body['total_count']).to eq(1)
        expect(response_body['time_spent']).to eq(classification_event.session_time)
        expect(response_body['data'].length).to eq(1)
        expect(response_body['data'][0]['period']).to eq("#{Date.today}T00:00:00.000Z")
        expect(response_body['data'][0]['count']).to eq(1)
        expect(response_body['data'][0]['session_time']).to eq(classification_event.session_time)
      end

      it 'returns unique project contributions count if querying for project_contributions' do
        get :query, params: { id: classification_event.user_id, project_contributions: true }
        expect(response.status).to eq(200)
        response_body = JSON.parse(response.body)
        expect(response_body['project_contributions'].length).to eq(1)
        expect(response_body['project_contributions'][0]['project_id']).to eq(classification_event.project_id)
      end

      it 'returns user project classification counts without session_time if time_spent is false' do
        get :query, params: { id: classification_event.user_id, project_id: 1, period: 'day' }
        expect(response.status).to eq(200)
        response_body = JSON.parse(response.body)
        expect(response_body['data'][0]).not_to have_key('session_time')
      end
    end

    context 'zooniverse_admin' do
      before(:each) { authenticate!(is_panoptes_admin: true) }
      it 'returns successful response' do
        get :query, params: { id: classification_event.user_id.to_s }
        expected_response = { total_count: 1 }
        expect(response.status).to eq(200)
        expect(response.body).to eq(expected_response.to_json)
      end
    end

    context 'not authorized user' do
      before(:each) { authenticate! }

      it 'returns a 403 not authorized response' do
        get :query, params: { id: classification_event.user_id.to_s }
        expect(response.status).to eq(403)
      end
    end

    context 'missing token' do
      it_behaves_like 'returns 403 when authorization header is invalid' do
        before(:each) {
          get :query, params: { id: classification_event.user_id.to_s }
        }
      end
    end

    it 'returns forbidden if panoptes fails to find user' do
      allow(controller).to receive(:client).and_raise(Panoptes::Client::ServerError, 'an error')
      get :query, params: { id: classification_event.user_id.to_s }
      expected_response = { error: 'Could not check authentication with Panoptes' }
      expect(response.status).to eq(403)
      expect(response.body).to eq(expected_response.to_json)
    end

    context 'param validations' do
      it_behaves_like 'ensure valid query params', :query, id: 1

      it 'ensures you cannot query by workflow and project_contributions' do
        get :query, params:  { id: 1, project_contributions: true, workflow_id: 1 }
        expect(response.status).to eq(400)
        expect(response.body).to include('Cannot query for project contributions and query by project/workflow')
      end

      it 'ensures you cannot query by project and top project contributions' do
        get :query, params: { id: 1, project_contributions: true, project_id: 1 }
        expect(response.status).to eq(400)
        expect(response.body).to include('Cannot query for project contributions and query by project/workflow')
      end

      it 'ensures project_contributions is an boolean' do
        get :query, params: { id: 1, project_contributions: '100' }
        expect(controller.params[:project_contributions]).to eq(false)
      end

      it 'ensures project_contributions is true if given string true' do
        get :query, params: { id: 1, project_contributions: 'true' }
        expect(controller.params[:project_contributions]).to eq(true)
      end

      it 'ensures time_spent is a boolean' do
        get :query, params: { id: 1, time_spent: 'not true' }
        expect(controller.params[:time_spent]).to eq(false)
      end

      it 'ensures time_spent is true if given string true' do
        get :query, params: { id: 1, time_spent: 'true' }
        expect(controller.params[:time_spent]).to eq(true)
      end
    end
  end
end
