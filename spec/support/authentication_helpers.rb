# frozen_string_literal: true

module AuthenticationHelpers
  def authenticate!(user_id='9999', is_panoptes_admin: false)
    allow(controller).to receive(:client).and_return(user_client(user_id, is_panoptes_admin))
  end

  def authenticate_with_membership!(classification_user_group, memberships, is_panoptes_admin: false)
    allow(controller).to receive(:client).and_return(user_client_with_membership(classification_user_group, memberships, is_panoptes_admin))
  end

  def panoptes_application_client
    @panoptes_application_client ||= instance_double(Panoptes::Client)
  end

  def user_client_with_membership(classification_user_group, memberships, is_panoptes_admin)
    return @user_client_with_membership if @user_client_with_membership

    me_hash = {
      'id' => classification_user_group.user_id,
      'login' => 'login',
      'display_name' => 'display_name',
      'admin' => is_panoptes_admin
    }
    memberships_url = "/memberships?user_id=#{classification_user_group.user_id}&user_group_id=#{classification_user_group.user_group_id}"

    @user_client_with_membership = double(Panoptes::Client, me: me_hash).tap do |client|
      allow(client).to receive(:is_a?).and_return(false)
      allow(client).to receive(:is_a?).with(Panoptes::Client).and_return(true)
      allow(client).to receive_message_chain(:panoptes, :get).with(memberships_url).and_return('memberships' => memberships)
    end

    @user_client_with_membership
  end

  def user_client(user_id, is_panoptes_admin)
    return @user_client if @user_client

    me_hash = {
      'id' => user_id,
      'login' => 'login',
      'display_name' => 'display_name',
      'admin' => is_panoptes_admin
    }

    @user_client = double(Panoptes::Client, me: me_hash).tap do |client|
      allow(client).to receive(:is_a?).and_return(false)
      allow(client).to receive(:is_a?).with(Panoptes::Client).and_return(true)
    end

    @user_client
  end
end
