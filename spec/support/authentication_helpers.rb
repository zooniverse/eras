# frozen_string_literal: true

module AuthenticationHelpers
  def authenticate!(user_id='9999', is_panoptes_admin: false)
    allow(controller).to receive(:client).and_return(user_client(user_id, is_panoptes_admin))
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
