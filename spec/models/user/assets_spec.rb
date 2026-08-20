# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe User::Assets do
  subject(:agent) do
    create(:agent, phone: '+49 30 111111', mobile: '+49 170 222222', note: 'internal note')
  end

  let(:sensitive_attributes) { %w[phone mobile note street zip city country department] }

  # The shared asset examples run in a system context because they are about the asset structure,
  # so these examples cover the unprivileged default that the redaction depends on.
  describe '#filter_unauthorized_attributes' do
    it 'redacts sensitive attributes without a user context' do
      UserInfo.reset

      expect(agent.attributes_with_association_ids.keys).not_to include(*sensitive_attributes)
    end

    it 'returns them in a system context' do
      expect(UserInfo.with_system_context { agent.attributes_with_association_ids }.keys)
        .to include(*sensitive_attributes)
    end

    it 'redacts sensitive attributes for a customer' do
      UserInfo.current_user_id = create(:customer).id

      expect(agent.attributes_with_association_ids.keys).not_to include(*sensitive_attributes)
    end

    it 'returns them for an agent' do
      UserInfo.current_user_id = create(:agent).id

      expect(agent.attributes_with_association_ids.keys).to include(*sensitive_attributes)
    end
  end

  describe '#assets_accounts' do
    before { create(:twitter_authorization, user: agent) }

    it 'omits linked accounts without a user context' do
      UserInfo.reset

      expect(agent.assets({})[User.to_app_model][agent.id]).not_to include('accounts')
    end

    it 'includes them in a system context' do
      assets = UserInfo.with_system_context { agent.assets({}) }

      expect(assets[User.to_app_model][agent.id]).to include('accounts')
    end
  end
end
