# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Organization::Assets do
  subject(:organization) do
    create(:organization, note: 'internal note', domain: 'internal.example.com', vip: true)
  end

  let(:sensitive_attributes) { %w[note domain vip member_ids secondary_member_ids] }

  def attributes_for_user(user)
    UserInfo.with_user_id(user.id) { organization.attributes_with_association_ids }
  end

  describe '#filter_unauthorized_attributes' do
    it 'redacts internal attributes without a user context' do
      UserInfo.reset

      expect(organization.attributes_with_association_ids.keys).not_to include(*sensitive_attributes)
    end

    it 'returns them in a system context' do
      expect(UserInfo.with_system_context { organization.attributes_with_association_ids }.keys)
        .to include(*sensitive_attributes)
    end

    it 'redacts internal attributes for a customer' do
      UserInfo.current_user_id = create(:customer).id

      expect(organization.attributes_with_association_ids.keys).not_to include(*sensitive_attributes)
    end

    it 'returns them for an agent' do
      UserInfo.current_user_id = create(:agent).id

      expect(organization.attributes_with_association_ids.keys).to include(*sensitive_attributes)
    end

    it 'exposes only the public attributes to a member customer' do
      customer = create(:customer, organization: organization)

      expect(attributes_for_user(customer))
        .to include('id' => organization.id, 'name' => organization.name, 'active' => true)
        .and not_include('note', 'domain', 'member_ids', 'secondary_member_ids', 'shared', 'vip')
    end

    it 'hides the secondary members from a secondary member customer' do
      customer = create(:customer, organization: create(:organization), organizations: [organization])

      expect(attributes_for_user(customer)).not_to include('secondary_member_ids')
    end

    it 'exposes all attributes to an admin' do
      expect(attributes_for_user(create(:admin)))
        .to include('note' => 'internal note', 'domain' => 'internal.example.com', 'secondary_member_ids' => [])
    end
  end
end
