# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'SAML Authentication', authenticated_as: false, integration: true, required_envs: %w[KEYCLOAK_BASE_URL KEYCLOAK_ADMIN KEYCLOAK_ADMIN_PASSWORD], type: :system do
  # Shared/persistent variables
  saml_initialized = false
  saml_access_token = ''

  let(:saml_base_url)                { ENV['KEYCLOAK_BASE_URL'] }
  let(:zammad_base_url)              { "#{Capybara.app_host}:#{Capybara.current_session.server.port}" }
  let(:saml_auth_endpoint)           { "#{saml_base_url}/realms/master/protocol/openid-connect/token" }
  let(:saml_auth_payload)            { { username: ENV['KEYCLOAK_ADMIN'], password: ENV['KEYCLOAK_ADMIN_PASSWORD'], grant_type: 'password', client_id: 'admin-cli' } }
  let(:saml_client_import_endpoint)  { "#{saml_base_url}/admin/realms/zammad/clients" }
  let(:saml_auth_headers)            { { Authorization: "Bearer #{saml_access_token}" } }
  let(:saml_client_json)             { Rails.root.join('test/data/saml/zammad-client.json').read.gsub('ZAMMAD_BASE_URL', zammad_base_url) }
  let(:saml_realm_zammad_descriptor) { "#{saml_base_url}/realms/zammad/protocol/saml/descriptor" }
  let(:saml_realm_zammad_accounts)   { "#{saml_base_url}/realms/zammad/account" }

  # Only before(:each) can access let() variables.
  before do
    next if saml_initialized

    # Get auth token.
    response = UserAgent.post(saml_auth_endpoint, saml_auth_payload)
    raise 'Authentication failed' if !response.success?

    saml_access_token = JSON.parse(response.body)['access_token']
    raise 'No access_token found' if saml_access_token.blank?

    # Import zammad client.
    response = UserAgent.post(saml_client_import_endpoint, JSON.parse(saml_client_json), { headers: saml_auth_headers, json: true, jsonParseDisable: true })
    raise 'Authentication failed' if !response.success?

    saml_initialized = true
  end

  def set_saml_config(name_identifier_format: nil, uid_attribute: nil)
    # Setup Zammad SAML authentication.
    response = UserAgent.get(saml_realm_zammad_descriptor)
    raise 'No Zammad realm descriptor found' if !response.success?

    match = response.body.match(%r{<ds:X509Certificate>(?<cert>.+)</ds:X509Certificate>})
    raise 'No X509Certificate found' if !match[:cert]

    auth_saml_credentials =
      {
        display_name:           'SAML',
        idp_sso_target_url:     "#{saml_base_url}/realms/zammad/protocol/saml",
        idp_slo_service_url:    "#{saml_base_url}/realms/zammad/protocol/saml",
        idp_cert:               "-----BEGIN CERTIFICATE-----\n#{match[:cert]}\n-----END CERTIFICATE-----",
        name_identifier_format: name_identifier_format || 'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress',
      }
    auth_saml_credentials[:uid_attribute] = uid_attribute if uid_attribute
    Setting.set('auth_saml_credentials', auth_saml_credentials)
    Setting.set('auth_saml', true)
    Setting.set('fqdn', zammad_base_url.gsub(%r{^https?://}, ''))
  end

  # Shared_examples does not work.
  def login_saml(app: 'desktop')
    case app
    when 'desktop'
      visit '/#login'
      find('.auth-provider--saml').click
    when 'mobile'
      visit '/login', app: :mobile
      find('.icon-mobile-saml').click
    end

    login_saml_keycloak

    check_logged_in(app: app)
  end

  def login_saml_keycloak
    find_by_id('kc-form')
    expect(page).to have_current_path(%r{/realms/zammad/protocol/saml\?SAMLRequest=.+})
    expect(page).to have_css('#kc-form-login')

    within '#kc-form-login' do
      fill_in 'username', with: 'john.doe'
      fill_in 'password', with: 'test'

      click_button
    end
  end

  def check_logged_in(app: 'desktop')
    find_by_id('app')

    case app
    when 'desktop'
      expect(page).to have_current_route('ticket/view/my_tickets')
    when 'mobile'
      # FIXME: Workaround because the redirect to the mobile app is not working due to a not set HTTP Referer in Capybara.
      visit '/', app: :mobile
      expect(page).to have_text('Home')
    end
  end

  def logout_saml
    visit '/#logout'
    expect(page).to have_current_route('login')
    find_by_id('app')
  end

  describe 'SP login and SP logout' do
    before do
      set_saml_config
    end

    it 'is successful' do
      login_saml

      visit saml_realm_zammad_accounts
      expect(page).to have_css('#landingSignOutButton')
      find_by_id('landingWelcomeMessage')

      logout_saml

      visit saml_realm_zammad_accounts
      expect(page).to have_no_css('#landingSignOutButton')
      find_by_id('landingWelcomeMessage')
    end
  end

  describe 'SP login and IDP logout' do
    before do
      set_saml_config
    end

    it 'is successful' do
      login_saml

      visit saml_realm_zammad_accounts

      find_by_id('landingWelcomeMessage')
      find('#landingSignOutButton').click

      visit '/'
      expect(page).to have_current_route('login')
      find_by_id('app')
    end
  end

  describe "use custom user attribute 'uid' as uid_attribute" do
    before do
      set_saml_config(uid_attribute: 'uid')
    end

    it 'is successful' do
      login_saml

      user = User.find_by(email: 'john.doe@saml.example.com')
      expect(user.login).to eq('73f7c02f-77b1-4cb7-9a2a-0e7a3aeeda52')

      logout_saml
    end
  end

  describe 'use unspecified (IDP provided) name identifier' do
    before do
      set_saml_config(name_identifier_format: 'urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified')
    end

    it 'is successful' do
      login_saml

      user = User.find_by(email: 'john.doe@saml.example.com')
      expect(user.login).to eq('john.doe')

      logout_saml
    end
  end

  describe 'Mobile View', app: :mobile do
    context 'when login is tested' do
      before do
        set_saml_config
      end

      it 'is successful' do
        login_saml(app: 'mobile')

        visit saml_realm_zammad_accounts
        find('#landingMobileKebabButton').click
        expect(page).to have_css('#landingSignOutLink')
      end
    end

    context 'when logout is tested' do
      before do
        set_saml_config
      end

      it 'is successful' do
        login_saml(app: 'mobile')

        visit '/account', app: :mobile
        click_button('Sign out')

        wait.until do
          expect(page).to have_button('Sign in')
        end

        visit saml_realm_zammad_accounts
        find('#landingMobileKebabButton').click
        expect(page).to have_no_css('#landingSignOutLink')
        find_by_id('landingWelcomeMessage')
      end
    end

    context 'when saml user already exists with agent role' do
      before do
        Setting.set('auth_third_party_auto_link_at_inital_login', true)
        create(:agent, email: 'john.doe@saml.example.com', login: 'john.doe', firstname: 'John', lastname: 'Doe')

        set_saml_config
      end

      it 'is successful' do
        login_saml(app: 'mobile')

        visit saml_realm_zammad_accounts
        find('#landingMobileKebabButton').click
        expect(page).to have_css('#landingSignOutLink')
      end
    end
  end
end
