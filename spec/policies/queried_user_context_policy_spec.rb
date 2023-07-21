# frozen_string_literal: true

RSpec.describe QueriedUserContextPolicy do
  let(:querying_user) {
    {
      'id' => '1234',
      'login' => 'login',
      'display_name' => 'display_name'
    }
  }
  let(:record) { QueriedUserContext.new('9') }

  permissions :show? do
    it 'permits querying_user to query if panoptes admin' do
      querying_user['admin'] = true
      expect(described_class).to permit(querying_user, record)
    end

    it 'permits querying_user to query their own stats' do
      querying_user['id'] = 9
      expect(described_class).to permit(querying_user, record)
    end

    it 'forbids unauthorized users' do
      expect(described_class).not_to permit(querying_user, record)
    end

    it 'forbids unauthorized requests' do
      expect(described_class).not_to permit(querying_user, record)
    end
  end
end
