# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe User::Assets do
  subject(:agent) do
    create(:agent, phone: '+49 30 111111', mobile: '+49 170 222222', note: 'internal note', last_login: Time.zone.now, login_failed: 1)
  end

  let(:sensitive_attributes) { %w[phone mobile note street zip city country department] }

  def assets_of(record, viewer:)
    UserInfo.with_user_id(viewer.id) { record.assets({}) }.dig(User.to_app_model, record.id)
  end

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

    context 'when a customer looks at another user' do
      it 'exposes only the public name attributes' do
        expect(assets_of(agent, viewer: create(:customer)).keys)
          .to contain_exactly('id', 'firstname', 'lastname', 'image', 'image_source', 'active')
      end
    end

    context 'when a customer looks at the own user' do
      let(:customer) { create(:customer, organization: create(:organization), note: 'hello', phone: '+49 123', login_failed: 1) }

      it 'exposes the account attributes but not the contact details or the note' do
        expect(assets_of(customer, viewer: customer))
          .to include('email' => customer.email, 'organization_id' => customer.organization_id, 'login_failed' => 1)
          .and not_include('note', 'phone', 'web', 'mobile', 'fax', 'department', 'street', 'zip', 'city', 'country', 'address')
      end
    end

    shared_examples 'exposing all attributes' do
      it 'exposes the details of other users' do
        expect(assets_of(agent, viewer: viewer))
          .to include('email' => agent.email, 'note' => 'internal note', 'login_failed' => 1, 'last_login' => be_present)
          .and not_include('password')
      end
    end

    context 'when an agent looks at another user' do
      let(:viewer) { create(:agent) }

      include_examples 'exposing all attributes'
    end

    context 'when an admin looks at another user' do
      let(:viewer) { create(:admin) }

      include_examples 'exposing all attributes'
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

    it 'hides the accounts of another user from a customer' do
      expect(assets_of(agent, viewer: create(:customer))).not_to have_key('accounts')
    end

    it 'shows the accounts of another user to an agent' do
      expect(assets_of(agent, viewer: create(:agent))).to include('accounts' => include('twitter'))
    end
  end
end
