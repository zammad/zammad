# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'system/examples/sso_role_mapping_examples'

RSpec.describe 'OpenID Connect Authentication', authenticated_as: false, integration: true, integration_standalone: :oidc, required_envs: %w[KEYCLOAK_BASE_URL KC_BOOTSTRAP_ADMIN_USERNAME KC_BOOTSTRAP_ADMIN_PASSWORD], type: :system do
  let(:zammad_base_url) { "#{Capybara.app_host}:#{Capybara.current_session.server.port}" }

  let(:idp_client_uuid) { oidc_configure_keycloak(zammad_base_url:) }

  before do
    idp_client_uuid
    oidc_configure_zammad
  end

  def login_via_idp
    visit '/#login'
    find('.auth-provider--openid-connect').click

    oidc_login_keycloak
  end

  def logout_via_idp
    await_empty_ajax_queue
    logout
    expect_current_route 'login'
  end

  describe 'login and logout' do
    after { keycloak_logout_user }

    it 'is successful' do
      login_via_idp

      expect(page).to have_current_route('ticket/view/my_tickets')
      expect(User.find_by(email: 'john.doe@saml.example.com')).to have_attributes(firstname: 'John', lastname: 'Doe')

      logout_via_idp
    end
  end

  describe 'role mapping' do
    it_behaves_like 'assigning roles from the identity provider', provider: 'openid_connect', attribute: 'zammad_roles'
  end
end
