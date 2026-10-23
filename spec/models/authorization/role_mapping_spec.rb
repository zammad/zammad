# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Authorization::RoleMapping, type: :model do
  subject(:role_mapping) { described_class.new(auth_hash) }

  let(:provider)      { 'openid_connect' }
  let(:raw_info)      { { 'roles' => ['zammad-agent'] } }
  let(:auth_hash)     { { 'provider' => provider, 'uid' => 'jdoe', 'extra' => { 'raw_info' => raw_info } } }
  let(:agent_role)    { create(:role, :agent) }
  let(:admin_role)    { create(:role, :admin) }
  let(:customer_role) { create(:role, :customer) }
  let(:attribute)     { 'roles' }
  let(:unmatched)     { 'signup_roles' }
  let(:config) do
    {
      'attribute' => attribute,
      'map'       => {
        'zammad-agent' => [agent_role.id.to_s],
        'zammad-admin' => [admin_role.id.to_s, agent_role.id.to_s],
      },
      'unmatched' => unmatched,
    }
  end

  before do
    # Without validation, since SAML requires credentials the role mapping does not depend on.
    setting = Setting.find_by(name: "auth_#{provider}_credentials")
    setting.state_current = { value: { 'role_mapping' => config } }
    setting.save!(validate: false)
  end

  describe '#verify!' do
    context 'when no role is mapped and logins without a mapped role are denied' do
      let(:raw_info)  { { 'roles' => ['unknown'] } }
      let(:unmatched) { 'deny' }

      it 'raises an account error' do
        expect { role_mapping.verify! }
          .to raise_error(Authorization::Provider::AccountError, 'Your identity provider does not grant you access to this system. Please contact your administrator.')
      end
    end

    context 'when no role is mapped and signup roles are assigned instead' do
      let(:raw_info) { { 'roles' => ['unknown'] } }

      it 'does not raise' do
        expect { role_mapping.verify! }.not_to raise_error
      end
    end

    context 'when a role is mapped and logins without a mapped role are denied' do
      let(:unmatched) { 'deny' }

      it 'does not raise' do
        expect { role_mapping.verify! }.not_to raise_error
      end
    end

    context 'when the mapped role IDs do not exist' do
      let(:unmatched) { 'deny' }
      let(:config)    { { 'attribute' => attribute, 'map' => { 'zammad-agent' => [Role.maximum(:id) + 1] }, 'unmatched' => unmatched } }

      it 'raises an account error' do
        expect { role_mapping.verify! }.to raise_error(Authorization::Provider::AccountError)
      end
    end

    context 'when the role mapping is not configured' do
      let(:raw_info) { {} }
      let(:config)   { {} }

      it 'does not raise' do
        expect { role_mapping.verify! }.not_to raise_error
      end
    end
  end

  describe '#apply' do
    let(:user)           { create(:customer, roles: [customer_role]) }
    let(:debug_messages) { [] }

    before do
      allow(Rails.logger).to receive(:debug) { |&block| debug_messages << block&.call }
    end

    context 'when a role is mapped' do
      it 'replaces all roles of the user' do
        role_mapping.apply(user)

        expect(user.reload.roles).to contain_exactly(agent_role)
      end

      it 'writes the change to the debug log' do
        role_mapping.apply(user)

        expect(debug_messages).to include("Changed the roles of user '#{user.login}' via openid_connect from [#{customer_role.id}] to [#{agent_role.id}], mapped from the values [\"zammad-agent\"] of 'roles'.")
      end

      it 'does not write to the debug log if the roles are unchanged' do
        user.update!(roles: [agent_role])
        role_mapping.apply(user)

        expect(debug_messages.grep(%r{Changed the roles})).to be_empty
      end

      it 'logs the change with the user as actor' do
        Setting.set('system_init_done', true)
        role_mapping.apply(user)

        expect(AuditLog.find_by(auditable: user, action_type: 'update')).to have_attributes(
          user_id:  user.id,
          value_to: { 'roles' => [agent_role.name] },
        )
      end
    end

    context 'when several values are mapped' do
      let(:raw_info) { { 'roles' => %w[zammad-agent zammad-admin unknown] } }

      it 'assigns the roles of all values and ignores unknown values' do
        role_mapping.apply(user)

        expect(user.reload.roles).to contain_exactly(agent_role, admin_role)
      end
    end

    context 'when the claim is a single value' do
      let(:raw_info) { { 'roles' => 'zammad-agent' } }

      it 'assigns the mapped roles' do
        role_mapping.apply(user)

        expect(user.reload.roles).to contain_exactly(agent_role)
      end
    end

    context 'when the claim is nested' do
      let(:attribute) { 'resource_access.zammad.roles' }
      let(:raw_info)  { { 'resource_access' => { 'zammad' => { 'roles' => ['zammad-agent'] } } } }

      it 'assigns the mapped roles' do
        role_mapping.apply(user)

        expect(user.reload.roles).to contain_exactly(agent_role)
      end
    end

    context 'when the values differ in case' do
      let(:raw_info) { { 'roles' => ['Zammad-Agent'] } }

      it 'assigns the signup roles' do
        role_mapping.apply(user)

        expect(user.reload.role_ids).to match_array(Role.signup_role_ids)
      end
    end

    context 'when no role is mapped' do
      let(:user)     { create(:agent, roles: [agent_role]) }
      let(:raw_info) { { 'roles' => ['unknown'] } }

      it 'assigns the signup roles' do
        role_mapping.apply(user)

        expect(user.reload.role_ids).to match_array(Role.signup_role_ids)
      end

      it 'writes the fallback to the debug log' do
        role_mapping.apply(user)

        expect(debug_messages).to include(a_string_ending_with("no role is mapped for the values [\"unknown\"] of 'roles', assigned the signup roles."))
      end
    end

    context 'with SAML attributes' do
      let(:provider)  { 'saml' }
      let(:attribute) { 'http://schemas.example.com/claims/role' }
      let(:raw_info)  { OneLogin::RubySaml::Attributes.new(attribute => %w[zammad-agent zammad-admin]) }

      it 'assigns the roles of all values of the attribute' do
        role_mapping.apply(user)

        expect(user.reload.roles).to contain_exactly(agent_role, admin_role)
      end
    end

    context 'when the role mapping is not configured' do
      let(:config) { {} }

      it 'keeps the roles' do
        expect { role_mapping.apply(user) }.not_to change { user.reload.role_ids }
      end
    end

    context 'with a provider that does not support the role mapping' do
      let(:auth_hash) { { 'provider' => 'github', 'uid' => 'jdoe', 'extra' => { 'raw_info' => raw_info } } }

      it 'keeps the roles' do
        expect { role_mapping.apply(user) }.not_to change { user.reload.role_ids }
      end
    end

    context 'when the user is synced from LDAP' do
      let(:group_role_map) { { 'cn=agents,dc=example,dc=com' => [agent_role.id.to_s] } }
      let(:ldap_source)    { create(:ldap_source, preferences: { group_role_map: group_role_map }) }
      let(:user)           { create(:customer, roles: [customer_role], source: "Ldap::#{ldap_source.id}") }

      before { Setting.set('ldap_integration', true) }

      it 'keeps the roles if the LDAP source maps groups to roles' do
        expect { role_mapping.apply(user) }.not_to change { user.reload.role_ids }
      end

      context 'without a group role map' do
        let(:group_role_map) { {} }

        it 'assigns the mapped roles' do
          role_mapping.apply(user)

          expect(user.reload.roles).to contain_exactly(agent_role)
        end
      end

      context 'with the LDAP integration being disabled' do
        before { Setting.set('ldap_integration', false) }

        it 'assigns the mapped roles' do
          role_mapping.apply(user)

          expect(user.reload.roles).to contain_exactly(agent_role)
        end
      end

      context 'with the LDAP source being inactive' do
        before { ldap_source.update!(active: false) }

        it 'assigns the mapped roles' do
          role_mapping.apply(user)

          expect(user.reload.roles).to contain_exactly(agent_role)
        end
      end
    end

    context 'when the user loses the admin role' do
      let(:user) { create(:admin, roles: [admin_role]) }

      it 'removes the admin role if another admin exists' do
        create(:admin, roles: [admin_role])

        role_mapping.apply(user)

        expect(user.reload.roles).to contain_exactly(agent_role)
      end

      it 'keeps the admin role of the last admin' do
        allow(User).to receive(:admin_user_exists?).and_return(false)

        role_mapping.apply(user)

        expect(user.reload.roles).to contain_exactly(admin_role, agent_role)
      end
    end

    context 'when the agent limit is reached' do
      before do
        Setting.set('system_agent_limit', User.with_permissions('ticket.agent').where(active: true).distinct.count)
      end

      it 'keeps the roles' do
        expect { role_mapping.apply(user) }.not_to change { user.reload.role_ids }
      end
    end
  end
end
