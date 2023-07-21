# frozen_string_literal: true

RSpec.describe ApplicationPolicy, type: :policy do
  let(:records) { [] }
  let(:user) {
    {
      'id' => '1234',
      'login' => 'login',
      'display_name' => 'display_name'
    }
  }
  let(:policy) { ApplicationPolicy.new user, records }

  context 'with a user' do
    it 'sets panoptes_admin? to be false if user is not a panoptes admin' do
      expect(policy.panoptes_admin?).to be false
    end

    it 'sets panoptes_admin? to true if user is panoptes admin' do
      user['admin'] = true
      ApplicationPolicy.new user, records
      expect(policy.panoptes_admin?).to be true
    end
  end

  context 'without a user' do
    it 'is not logged in' do
      expect { ApplicationPolicy.new(nil, records) }.to raise_error Pundit::NotAuthorizedError
    end
  end
end
