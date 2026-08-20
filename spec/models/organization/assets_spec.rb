# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Organization::Assets do
  subject(:organization) do
    create(:organization, note: 'internal note', domain: 'internal.example.com', vip: true)
  end

  let(:sensitive_attributes) { %w[note domain vip member_ids] }

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
  end
end
