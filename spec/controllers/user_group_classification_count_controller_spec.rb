# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserGroupClassificationCountController do
  describe 'GET query' do
    let!(:classification_user_group) { create(:classification_user_group) }

    context 'individual_stats_breakdown is false/not a param' do
      it 'returns total_count, time_spent, active_users, and project_contributions of user group' do
        get :query, params: { id: classification_user_group.user_group_id.to_s }
        expect(response.status).to eq(200)
        response_body = JSON.parse(response.body)
        expect(response_body['total_count']).to eq(1)
        expect(response_body['time_spent']).to eq(classification_user_group.session_time)
        expect(response_body['active_users']).to eq(1)
        expect(response_body['project_contributions'].length).to eq(1)
      end

      it 'does not compute project_contributions when params[:project_id] given' do
        get :query, params: { id: classification_user_group.user_group_id.to_s, project_id: 2 }
        expect(response.status).to eq(200)
        response_body = JSON.parse(response.body)
        expect(response_body).not_to have_key('project_contributions')
      end

      it 'does not compute project_contributions when params[:workflow_id] given' do
        get :query, params: { id: classification_user_group.user_group_id.to_s, workflow_id: 2 }
        expect(response.status).to eq(200)
        response_body = JSON.parse(response.body)
        expect(response_body).not_to have_key('project_contributions')
      end
    end

    context 'individual_stats_breakdown is true' do
      it 'returns group_member_stats_breakdown' do
        get :query, params: { id: classification_user_group.user_group_id.to_s, individual_stats_breakdown: true }
        expect(response.status).to eq(200)
        response_body = JSON.parse(response.body)
        expect(response_body).to have_key('group_member_stats_breakdown')
      end
    end

    context 'param validations' do
      it_behaves_like 'ensure valid query params', :query, id: 1

      it 'ensures you cannot query individual_stats_breakdown and any non date range param' do
        get :query, params: { id: 1, individual_stats_breakdown: true, project_id: 1 }
        expect(response.status).to eq(400)
        expect(response.body).to include('Cannot query individual stats breakdown with anything else EXCEPT start_date and end_date')
      end

      it 'ensures individual_stats_breakdown is a boolean' do
        get :query, params: { id: 1, individual_stats_breakdown: '100' }
        expect(controller.params[:individual_stats_breakdown]).to eq(false)
      end

      it 'ensures individual_stats_breakdown is true if given string true' do
        get :query, params: { id: 1, individual_stats_breakdown: 'true' }
        expect(controller.params[:individual_stats_breakdown]).to eq(true)
      end

      it 'ensures top_contributors is an integer' do
        get :query, params: { id: 1, top_contributors: '10' }
        expect(controller.params[:top_contributors]).to eq(10)
      end
    end
  end
end
