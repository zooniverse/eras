# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserGroupClassificationCountController do
  include AuthenticationHelpers

  describe 'GET query' do
    let!(:classification_user_group) { create(:classification_user_group) }

    shared_examples 'shows group aggregate stats' do
      it 'returns total_count, time_spent, active_users, and project_contributions of user group' do
        get :query, params: { id: classification_user_group.user_group_id.to_s }
        expect(response.status).to eq(200)
        response_body = JSON.parse(response.body)
        expect(response_body['total_count']).to eq(1)
        expect(response_body['time_spent']).to eq(classification_user_group.session_time)
        expect(response_body['active_users']).to eq(1)
        expect(response_body['project_contributions'].length).to eq(1)
      end
    end

    shared_examples 'shows group individual stats breakdown' do
      it 'returns group_member_stats_breakdown' do
        get :query, params: { id: classification_user_group.user_group_id.to_s, individual_stats_breakdown: true }
        expect(response.status).to eq(200)
        response_body = JSON.parse(response.body)
        expect(response_body).to have_key('group_member_stats_breakdown')
      end
    end

    shared_context 'user_group member' do
      before(:each) {
        authenticate_with_membership!(classification_user_group, [membership(classification_user_group)])
      }
    end

    shared_context 'user_group admin' do
      before(:each) {
        authenticate_with_membership!(classification_user_group, [membership(classification_user_group, 'group_admin')])
      }
    end

    shared_context 'zooniverse admin' do
      before(:each) {
        authenticate_with_membership!(classification_user_group, [], is_panoptes_admin: true)
      }
    end

    shared_context 'user group with stats_visibility' do |stats_visibility|
      before(:each) {
        user_groups_url = "/user_groups/#{classification_user_group.user_group_id}"
        allow(panoptes_application_client).to receive_message_chain(:panoptes, :get).with(user_groups_url).and_return('user_groups' => [user_group(classification_user_group, stats_visibility)])
      }
    end

    before(:each) {
      allow(controller).to receive(:panoptes_application_client).and_return(panoptes_application_client)
    }

    context 'individual_stats_breakdown is false/not a param' do
      context 'public_show_all' do
        include_context 'user group with stats_visibility', 'public_show_all'
        context 'querying user is not a member' do
          before(:each) {
            authenticate_with_membership!(classification_user_group, [])
          }

          it_behaves_like 'shows group aggregate stats'

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

        context 'querying user is a group member' do
          include_context 'user_group member'
          it_behaves_like 'shows group aggregate stats'
        end

        context 'querying user is a group admin' do
          include_context 'user_group admin'
          it_behaves_like 'shows group aggregate stats'
        end

        context 'querying user is a zooniverse admin' do
          include_context 'zooniverse admin'
          it_behaves_like 'shows group aggregate stats'
        end
      end

      context 'public_agg_show_ind_if_member' do
        include_context 'user group with stats_visibility', 'public_agg_show_ind_if_member'

        context 'querying user is not a member' do
          before(:each) {
            authenticate_with_membership!(classification_user_group, [])
          }

          it_behaves_like 'shows group aggregate stats'
        end

        context 'querying user is a group member' do
          include_context 'user_group member'
          it_behaves_like 'shows group aggregate stats'
        end

        context 'querying user is a group admin' do
          include_context 'user_group admin'
          it_behaves_like 'shows group aggregate stats'
        end

        context 'querying user is a zooniverse admin' do
          include_context 'zooniverse admin'
          it_behaves_like 'shows group aggregate stats'
        end
      end

      context 'public_agg_only' do
        include_context 'user group with stats_visibility', 'public_agg_only'

        context 'querying user is not a member' do
          before(:each) {
            authenticate_with_membership!(classification_user_group, [])
          }

          it_behaves_like 'shows group aggregate stats'
        end

        context 'querying user is a group member' do
          include_context 'user_group member'
          it_behaves_like 'shows group aggregate stats'
        end

        context 'querying user is a group admin' do
          include_context 'user_group admin'
          it_behaves_like 'shows group aggregate stats'
        end

        context 'querying user is a zooniverse admin' do
          include_context 'zooniverse admin'
          it_behaves_like 'shows group aggregate stats'
        end
      end

      context 'private_show_agg_and_ind' do
        include_context 'user group with stats_visibility', 'private_show_agg_and_ind'

        context 'querying user is not a member' do
          before(:each) {
            authenticate_with_membership!(classification_user_group, [])
          }

          it 'does not show group aggregate stats' do
            get :query, params: { id: classification_user_group.user_group_id.to_s }
            expect(response.status).to eq(403)
          end
        end

        context 'querying user is a group member' do
          include_context 'user_group member'
          it_behaves_like 'shows group aggregate stats'
        end

        context 'querying user is a group admin' do
          include_context 'user_group admin'
          it_behaves_like 'shows group aggregate stats'
        end

        context 'querying user is a zooniverse admin' do
          include_context 'zooniverse admin'
          it_behaves_like 'shows group aggregate stats'
        end
      end

      context 'private_agg_only' do
        include_context 'user group with stats_visibility', 'private_agg_only'

        context 'querying user is not a member' do
          before(:each) {
            authenticate_with_membership!(classification_user_group, [])
          }

          it 'does not show group aggregate stats' do
            get :query, params: { id: classification_user_group.user_group_id.to_s }
            expect(response.status).to eq(403)
          end
        end

        context 'querying user is a group member' do
          include_context 'user_group member'
          it_behaves_like 'shows group aggregate stats'
        end

        context 'querying user is a group admin' do
          include_context 'user_group admin'
          it_behaves_like 'shows group aggregate stats'
        end

        context 'querying user is a zooniverse admin' do
          include_context 'zooniverse admin'
          it_behaves_like 'shows group aggregate stats'
        end
      end
    end

    context 'individual_stats_breakdown is true' do
      context 'public_show_all' do
        include_context 'user group with stats_visibility', 'public_show_all'

        context 'querying user is not a member' do
          before(:each) {
            authenticate_with_membership!(classification_user_group, [])
          }
          it_behaves_like 'shows group individual stats breakdown'
        end

        context 'querying user is a group member' do
          include_context 'user_group member'
          it_behaves_like 'shows group individual stats breakdown'
        end

        context 'querying user is a group admin' do
          include_context 'user_group admin'
          it_behaves_like 'shows group individual stats breakdown'
        end

        context 'querying user is a zooniverse admin' do
          include_context 'zooniverse admin'
          it_behaves_like 'shows group individual stats breakdown'
        end
      end

      context 'public_agg_show_ind_if_member' do
        include_context 'user group with stats_visibility', 'public_agg_show_ind_if_member'

        context 'querying user is not a member' do
          before(:each) {
            authenticate_with_membership!(classification_user_group, [])
          }

          it 'does not show individual stats breakdown' do
            get :query, params: { id: classification_user_group.user_group_id.to_s, individual_stats_breakdown: true }
            expect(response.status).to eq(403)
          end
        end

        context 'querying user is a group member' do
          include_context 'user_group member'
          it_behaves_like 'shows group individual stats breakdown'
        end

        context 'querying user is a group admin' do
          include_context 'user_group admin'
          it_behaves_like 'shows group individual stats breakdown'
        end

        context 'querying user is a zooniverse admin' do
          include_context 'zooniverse admin'
          it_behaves_like 'shows group individual stats breakdown'
        end
      end

      context 'public_agg_only' do
        include_context 'user group with stats_visibility', 'public_agg_only'

        context 'querying user is not a member' do
          before(:each) {
            authenticate_with_membership!(classification_user_group, [])
          }

          it 'does not show individual stats breakdown' do
            get :query, params: { id: classification_user_group.user_group_id.to_s, individual_stats_breakdown: true }
            expect(response.status).to eq(403)
          end
        end

        context 'querying user is a group member' do
          include_context 'user_group member'
          it 'does not show individual stats breakdown' do
            get :query, params: { id: classification_user_group.user_group_id.to_s, individual_stats_breakdown: true }
            expect(response.status).to eq(403)
          end
        end

        context 'querying user is a group admin' do
          include_context 'user_group admin'
          it_behaves_like 'shows group individual stats breakdown'
        end

        context 'querying user is a zooniverse admin' do
          include_context 'zooniverse admin'
          it_behaves_like 'shows group individual stats breakdown'
        end
      end

      context 'private_show_agg_and_ind' do
        include_context 'user group with stats_visibility', 'private_show_agg_and_ind'

        context 'querying user is not a member' do
          before(:each) {
            authenticate_with_membership!(classification_user_group, [])
          }

          it 'does not show individual stats breakdown' do
            get :query, params: { id: classification_user_group.user_group_id.to_s, individual_stats_breakdown: true }
            expect(response.status).to eq(403)
          end
        end

        context 'querying user is a group member' do
          include_context 'user_group member'
          it_behaves_like 'shows group individual stats breakdown'
        end

        context 'querying user is a group admin' do
          include_context 'user_group admin'
          it_behaves_like 'shows group individual stats breakdown'
        end

        context 'querying user is a zooniverse admin' do
          include_context 'zooniverse admin'
          it_behaves_like 'shows group individual stats breakdown'
        end
      end

      context 'private_agg_only' do
        include_context 'user group with stats_visibility', 'private_agg_only'

        context 'querying user is not a member' do
          before(:each) {
            authenticate_with_membership!(classification_user_group, [])
          }

          it 'does not show individual stats breakdown' do
            get :query, params: { id: classification_user_group.user_group_id.to_s, individual_stats_breakdown: true }
            expect(response.status).to eq(403)
          end
        end

        context 'querying user is a group member' do
          include_context 'user_group member'
          it 'does not show individual stats breakdown' do
            get :query, params: { id: classification_user_group.user_group_id.to_s, individual_stats_breakdown: true }
            expect(response.status).to eq(403)
          end
        end

        context 'querying user is a group admin' do
          include_context 'user_group admin'
          it_behaves_like 'shows group individual stats breakdown'
        end

        context 'querying user is a zooniverse admin' do
          include_context 'zooniverse admin'
          it_behaves_like 'shows group individual stats breakdown'
        end
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

  def membership(classification_user_group, role_type='group_member')
    { 'id' => 123,
      'user_group_id' => classification_user_group.user_group_id, 'user_id' => classification_user_group.user_id,
      'roles' => [role_type] }
  end

  def user_group(classification_user_group, stats_visibility)
    { 'id' => classification_user_group.user_group_id, 'stats_visibility' => stats_visibility }
  end
end
