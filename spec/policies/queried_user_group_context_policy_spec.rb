# frozen_string_literal: true

require 'rails_helper'

RSpec.describe QueriedUserGroupContextPolicy do
  let(:querying_user) {
    {
      'id' => '1234',
      'login' => 'login',
      'display_name' => 'display_name'
    }
  }

  permissions :show? do
    it 'permits querying_user to query if panoptes admin' do
      querying_user['admin'] = true
      expect(described_class).to permit(querying_user)
    end

    context 'individual stats breakdown requested' do
      before(:each) do
        querying_user['individual_stats_breakdown'] = true
      end

      it 'permits if group_stats_visibility is public_show_all' do
        querying_user['user_group_stats_visibility'] = 'public_show_all'
        expect(described_class).to permit(querying_user)
      end

      context 'public_agg_show_ind_if_member' do
        before(:each) do
          querying_user['user_group_stats_visibility'] = 'public_agg_show_ind_if_member'
        end
        it 'forbids if user is not a member' do
          expect(described_class).not_to permit(querying_user)
        end

        it 'permits if user is a member' do
          querying_user['user_membership'] = membership
          expect(described_class).to permit(querying_user)
        end
      end

      context 'private_show_agg_and_ind' do
        before(:each) do
          querying_user['user_group_stats_visibility'] = 'private_show_agg_and_ind'
        end
        it 'forbids if user is not a member' do
          expect(described_class).not_to permit(querying_user)
        end

        it 'permits if user is a member' do
          querying_user['user_membership'] = membership
          expect(described_class).to permit(querying_user)
        end
      end

      context 'public_agg_only' do
        before(:each) do
          querying_user['user_group_stats_visibility'] = 'public_agg_only'
        end
        it 'forbids if user is not a member' do
          expect(described_class).not_to permit(querying_user)
        end

        it 'forbids if user is a member' do
          querying_user['user_membership'] = membership
          expect(described_class).not_to permit(querying_user)
        end

        it 'permits if user is an admin' do
          querying_user['user_membership'] = membership('group_admin')
          expect(described_class).to permit(querying_user)
        end
      end

      context 'private_agg_only' do
        before(:each) do
          querying_user['user_group_stats_visibility'] = 'private_agg_only'
        end
        it 'forbids if user is not a member' do
          expect(described_class).not_to permit(querying_user)
        end

        it 'forbids if user is a member' do
          querying_user['user_membership'] = membership
          expect(described_class).not_to permit(querying_user)
        end

        it 'permits if user is an admin' do
          querying_user['user_membership'] = membership('group_admin')
          expect(described_class).to permit(querying_user)
        end
      end

      it 'forbids if group visibility is not of listed types' do
        querying_user['user_group_stats_visibility'] = 'other'
        expect(described_class).not_to permit(querying_user)
      end
    end

    context 'group aggregate stats' do
      it 'permits if group_stats_visibility is public_show_all' do
        querying_user['user_group_stats_visibility'] = 'public_show_all'
        expect(described_class).to permit(querying_user)
      end

      it 'permits if group_stats_visibility is public_agg_show_ind_if_member' do
        querying_user['user_group_stats_visibility'] = 'public_agg_show_ind_if_member'
        expect(described_class).to permit(querying_user)
      end

      it 'permits if group_stats_visibility is public_agg_only' do
        querying_user['user_group_stats_visibility'] = 'public_agg_only'
        expect(described_class).to permit(querying_user)
      end

      context 'private_show_agg_and_ind' do
        before(:each) do
          querying_user['user_group_stats_visibility'] = 'private_show_agg_and_ind'
        end

        it 'forbids if user is not a member' do
          expect(described_class).not_to permit(querying_user)
        end

        it 'permits if user is a group member' do
          querying_user['user_membership'] = membership
          expect(described_class).to permit(querying_user)
        end
      end

      context 'private_agg_only' do
        before(:each) do
          querying_user['user_group_stats_visibility'] = 'private_agg_only'
        end

        it 'forbids if user is not a group member' do
          expect(described_class).not_to permit(querying_user)
        end

        it 'permits if user is a group member' do
          querying_user['user_membership'] = membership
          expect(described_class).to permit(querying_user)
        end
      end
    end

    it 'forbids unauthorized users' do
      expect(described_class).not_to permit(querying_user)
    end
  end

  def membership(role_type='group_member')
    { 'id' => 123,
      'user_group_id' => 123,
      'user_id' => 123,
      'roles' => [role_type] }
  end
end
