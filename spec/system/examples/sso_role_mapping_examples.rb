# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Expects the including spec to provide the Keycloak client as `idp_client_uuid` and the
#   methods `login_via_idp`, which ends on the page after the login, and `logout_via_idp`.
RSpec.shared_examples 'assigning roles from the identity provider' do |provider:, attribute:|
  let(:agent_role)    { Role.find_by(name: 'Agent') }
  let(:customer_role) { Role.find_by(name: 'Customer') }
  let(:unmatched)     { 'signup_roles' }
  let(:idp_roles)     { [] }

  def sso_user
    User.find_by(email: 'john.doe@saml.example.com')
  end

  before do
    keycloak_create_client_roles(idp_client_uuid, %w[zammad-agent zammad-customer])
    keycloak_assign_client_roles(idp_client_uuid, idp_roles) if idp_roles.present?

    Setting.set("auth_#{provider}_credentials", Setting.get("auth_#{provider}_credentials").merge(
                                                  'role_mapping' => {
                                                    'attribute' => attribute,
                                                    'map'       => { 'zammad-agent' => [agent_role.id], 'zammad-customer' => [customer_role.id] },
                                                    'unmatched' => unmatched,
                                                  }
                                                ))
  end

  # A denied login leaves the session of the identity provider open.
  after { keycloak_logout_user }

  context 'with mapped roles' do
    let(:idp_roles) { %w[zammad-agent zammad-customer] }

    it 'assigns the mapped roles' do
      login_via_idp

      expect(page).to have_no_css('#kc-form-login')
      wait.until { sso_user&.roles&.to_a&.sort_by(&:id) == [agent_role, customer_role].sort_by(&:id) }
    end

    it 'revokes a role on the next login' do
      login_via_idp
      wait.until { sso_user&.roles&.include?(agent_role) }

      logout_via_idp
      keycloak_logout_user
      keycloak_revoke_client_roles(idp_client_uuid, %w[zammad-agent])

      login_via_idp
      expect(page).to have_no_css('#kc-form-login')

      wait.until { sso_user.reload.roles == [customer_role] }
    end
  end

  context 'without a mapped role' do
    context 'with an existing agent' do
      before do
        Setting.set('auth_third_party_auto_link_at_inital_login', true)
        create(:agent, email: 'john.doe@saml.example.com', firstname: 'John', lastname: 'Doe')
      end

      it 'replaces the roles with the signup roles' do
        login_via_idp

        expect(page).to have_no_css('#kc-form-login')
        wait.until { sso_user.reload.role_ids.sort == Role.signup_role_ids.sort }
      end
    end

    context 'when logins without a mapped role are denied' do
      let(:unmatched) { 'deny' }

      it 'denies the login without creating the user', :aggregate_failures do
        login_via_idp

        expect(page).to have_css('h1', text: '403: Forbidden')
        expect(page).to have_text('Your identity provider does not grant you access to this system.')
        expect(sso_user).to be_nil
      end
    end
  end
end
