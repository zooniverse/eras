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

      it 'returns total_count and time_spent and breakdown of user classifications wher period is given' do
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

      it 'returns top contributions and unique project contributions if querying for top_project_contributions' do
        get :query, params: { id: classification_event.user_id, top_project_contributions: 10 }
        expect(response.status).to eq(200)
        response_body = JSON.parse(response.body)
        expect(response_body['unique_project_contributions']).to eq(1)
        expect(response_body['top_project_contributions'].length).to eq(1)
        expect(response_body['top_project_contributions'][0]['project_id']).to eq(classification_event.project_id)
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
      it 'returns a 403 missing authorization header' do
        get :query, params: { id: classification_event.user_id.to_s }
        expected_response = { error: 'missing authorization header' }
        expect(response.status).to eq(403)
        expect(response.body).to eq(expected_response.to_json)
      end

      it 'returns a 403 missing when missing bearer token' do
        request.headers['Authorization'] = 'asjdhaskdhsa'
        get :query, params: { id: classification_event.user_id.to_s }
        expected_response = { error: 'missing bearer token' }
        expect(response.status).to eq(403)
        expect(response.body).to eq(expected_response.to_json)
      end
    end

    context 'param validations' do
      it_behaves_like 'ensure valid query params', :query, id: 1

      it 'ensures you cannot query by workflow and top_project_contributions' do
        get :query, params:  { id: 1, top_project_contributions: 10, workflow_id: 1 }
        expect(response.status).to eq(400)
        expect(response.body).to include('Cannot query top projects and query by project/workflow')
      end

      it 'ensures you cannot query by project and top project contributions' do
        get :query, params: { id: 1, top_project_contributions: 10, project_id: 1 }
        expect(response.status).to eq(400)
        expect(response.body).to include('Cannot query top projects and query by project/workflow')
      end

      it 'ensures top_project_contributions is an integer' do
        get :query, params: { id: 1, top_project_contributions: '20' }
        expect(controller.params[:top_project_contributions]).to eq(20)
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
