# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Login', app: :desktop_view, authenticated_as: false, type: :system do
  context 'when logging in with two factor auth' do
    let(:user)                 { User.find_by(login: 'admin@example.com') }
    let(:code)                 { two_factor_pref.configuration[:code] }
    let(:recover_code_enabled) { false }
    let!(:two_factor_pref)     { create(:user_two_factor_preference, :authenticator_app, user:) }
    let(:token)                { 'token' }

    before do
      Setting.set('two_factor_authentication_method_authenticator_app', true)

      visit '/login'

      login(
        username:     'admin@example.com',
        password:     'test',
        remember_me:  true,
        skip_waiting: true,
      )
    end

    it 'can login with correct code' do
      expect(page).to have_no_text('Try another method')

      find_input('Security Code').type(code)
      find_button('Sign in').click

      expect(page).to have_css('[aria-label="User menu"]')

      find('[aria-label="User menu"]').click
      click_on('Sign out')

      expect(page).to have_text('Sign in')
    end
  end

  context 'when loggin in via external authentication provider', authenticated_as: false, integration: true, integration_standalone: :saml, required_envs: %w[KEYCLOAK_BASE_URL KEYCLOAK_ADMIN_USER KEYCLOAK_ADMIN_PASSWORD] do
    let(:zammad_base_url)              { "#{Capybara.app_host}:#{Capybara.current_session.server.port}" }
    let(:zammad_saml_metadata)         { "#{zammad_base_url}/auth/saml/metadata" }
    let(:saml_base_url)                { ENV['KEYCLOAK_BASE_URL'] }
    let(:saml_client_json)             { Rails.root.join('test/data/saml/zammad-client.json').read.gsub('#ZAMMAD_BASE_URL', zammad_base_url) }
    let(:saml_realm_zammad_descriptor) { "#{saml_base_url}/realms/zammad/protocol/saml/descriptor" }
    let(:saml_realm_zammad_accounts)   { "#{saml_base_url}/realms/zammad/account" }

    before do
      saml_configure_keycloak(zammad_saml_metadata:, saml_client_json:)
      saml_configure_zammad(saml_base_url:, saml_realm_zammad_descriptor:)
    end

    it 'can login via external authentication provider' do
      visit '/login'
      expect(page).to have_text('Or sign in using')
      expect(page).to have_text('SAML')

      find_button('SAML').click

      saml_login_keycloak

      # Workaround: SAML redirects in CI don't work because of missing HTTP referrer headers.
      visit '/'
      expect(page).to have_css('[aria-label="User menu"]')

      find('[aria-label="User menu"]').click
      click_on('Sign out')

      expect(page).to have_current_path(%r{/login})
      wait_for_test_flag('applicationLoaded.loaded', skip_clearing: true)

      visit '/'
      expect_current_route '/login'

      visit saml_realm_zammad_accounts
      expect(page).to have_text('Sign in')
    end
  end
end
