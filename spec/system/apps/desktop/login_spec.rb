# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Login', app: :desktop_view, authenticated_as: false, type: :playwright do
  def sign_out(name)
    page.get_by_role('button', name:, exact: true).click
    page.get_by_role('link', name: 'Sign out', exact: true).click
  end

  context 'when logging in with two factor auth' do
    let(:user)             { User.find_by(login: 'admin@example.com') }
    let(:code)             { two_factor_pref.configuration[:code] }
    let!(:two_factor_pref) { create(:user_two_factor_preference, :authenticator_app, user:) }

    before do
      Setting.set('two_factor_authentication_method_authenticator_app', true)

      open_desktop('/login')
      sign_in(username: 'admin@example.com', password: 'test', remember_me: true)
    end

    it 'can login with correct code' do
      expect(main_content).to contain_text('Security code')
      expect(main_content).to not_contain_text('Try another method')

      fill_field('Security code', code)
      page.get_by_role('button', name: 'Sign in', exact: true).click

      sign_out(user.fullname)

      expect(page.get_by_role('button', name: 'Sign in', exact: true)).to be_visible
    end
  end

  context 'when logging in via external authentication provider', integration: true, integration_standalone: :saml, required_envs: %w[KEYCLOAK_BASE_URL KC_BOOTSTRAP_ADMIN_USERNAME KC_BOOTSTRAP_ADMIN_PASSWORD] do
    include_context 'when signing in via Keycloak SAML'

    it 'can login via external authentication provider' do
      open_desktop('/login')
      expect(page.get_by_text('Or sign in using')).to be_visible

      page.get_by_role('button', name: 'SAML').click
      saml_sign_in_keycloak

      # SAML redirects in CI do not work because of missing HTTP referrer headers.
      open_desktop('/')
      sign_out('John Doe')

      # Single logout passes through Keycloak and may come back to the legacy interface.
      expect(page.get_by_role('button', name: 'Sign in', exact: true)).to be_visible
      open_desktop('/')
      expect(page).to have_url(%r{/desktop/login$})

      page.goto(saml_realm_zammad_accounts)
      expect(page.locator('body')).to contain_text('Sign in')
    end
  end
end
