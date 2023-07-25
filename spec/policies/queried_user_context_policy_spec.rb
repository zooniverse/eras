# frozen_string_literal: true

RSpec.describe QueriedUserContextPolicy do
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

    it 'permits querying_user to query their own stats' do
      querying_user['queried_user_id'] = 1234
      expect(described_class).to permit(querying_user)
    end

    it 'forbids unauthorized users' do
      expect(described_class).not_to permit(querying_user)
    end
  end
end
