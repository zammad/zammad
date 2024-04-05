# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

require 'keycloak/admin'

RSpec.describe 'SAML Authentication', authenticated_as: false, integration: true, integration_standalone: :saml, required_envs: %w[KEYCLOAK_BASE_URL KEYCLOAK_ADMIN_USER KEYCLOAK_ADMIN_PASSWORD], type: :system do
  let(:zammad_base_url)              { "#{Capybara.app_host}:#{Capybara.current_session.server.port}" }
  let(:zammad_saml_metadata)         { "#{zammad_base_url}/auth/saml/metadata" }
  let(:saml_base_url)                { ENV['KEYCLOAK_BASE_URL'] }
  let(:saml_client_json)             { Rails.root.join('test/data/saml/zammad-client.json').read.gsub('#ZAMMAD_BASE_URL', zammad_base_url) }
  let(:saml_realm_zammad_descriptor) { "#{saml_base_url}/realms/zammad/protocol/saml/descriptor" }
  let(:saml_realm_zammad_accounts)   { "#{saml_base_url}/realms/zammad/account" }

  # Only before(:each) can access let() variables.
  before do
    saml_configure_keycloak(zammad_saml_metadata:, saml_client_json:)
  end

  # Shared_examples does not work.
  def login_saml(app: 'desktop')
    case app
    when 'desktop'
      visit '/#login'
      find('.auth-provider--saml').click
    when 'mobile'
      visit '/login', app: :mobile
      find('.icon-saml').click
    end

    saml_login_keycloak

    check_logged_in(app: app)
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
    await_empty_ajax_queue
    logout
    expect_current_route 'login'
    find_by_id('app')
  end

  # TODO: Should be replaced with tests for the new desktop-view (or the test in general should be removed outside of selenium).
  describe 'SP login and SP logout' do
    before do
      saml_configure_zammad(saml_base_url:, saml_realm_zammad_descriptor:, security:)
    end

    let(:security) { nil }

    it 'is successful' do
      login_saml

      visit saml_realm_zammad_accounts
      expect(page).to have_text('John Doe')

      logout_saml

      visit saml_realm_zammad_accounts
      expect(page).to have_text('Sign in')
    end

    context 'with client signature required and encrypted assertions enabled' do
      let(:security) do
        # generate a new private key and certificate
        key = OpenSSL::PKey::RSA.new(2048)
        cert = OpenSSL::X509::Certificate.new
        cert.subject = OpenSSL::X509::Name.parse('/CN=Zammad SAML Client')
        cert.issuer = cert.subject
        cert.not_before = Time.zone.now
        cert.not_after = (cert.not_before + (1 * 365 * 24 * 60 * 60)) # 1 year validity
        cert.public_key = key.public_key
        cert.serial = 0x0
        cert.version = 2

        ef = OpenSSL::X509::ExtensionFactory.new
        ef.subject_certificate = cert
        ef.issuer_certificate = cert
        cert.add_extension(ef.create_extension('keyUsage', 'digitalSignature, keyEncipherment', true))
        cert.add_extension(ef.create_extension('subjectKeyIdentifier', 'hash', false))
        cert.add_extension(ef.create_extension('basicConstraints', 'CA:FALSE', false))

        cert.sign(key, OpenSSL::Digest.new('SHA256'))

        pem = cert.to_pem
        pem.gsub!('-----BEGIN CERTIFICATE-----', '')
        pem.gsub!('-----END CERTIFICATE-----', '')
        pem.delete!("\n").strip!
        cert = pem

        pem = key.to_pem
        pem.gsub!('-----BEGIN RSA PRIVATE KEY-----', '') # gitleaks:allow
        pem.gsub!('-----END RSA PRIVATE KEY-----', '') # gitleaks:allow
        pem.delete!("\n").strip!
        key = pem

        {
          cert:,
          key:
        }
      end
      let(:saml_client_json) do
        client = Rails.root.join('test/data/saml/zammad-client-secure.json').read
        client.gsub!('#KEYCLOAK_ZAMMAD_BASE_URL', zammad_base_url)
        client.gsub!('#KEYCLOAK_ZAMMAD_CERTIFICATE', security[:cert])

        client
      end

      it 'is successful' do
        login_saml

        visit saml_realm_zammad_accounts
        expect(page).to have_text('John Doe')

        logout_saml

        visit saml_realm_zammad_accounts
        expect(page).to have_text('Sign in')
      end

    end
  end

  describe 'SP login and IDP logout' do
    before do
      saml_configure_zammad(saml_base_url:, saml_realm_zammad_descriptor:)
    end

    it 'is successful' do
      login_saml

      visit saml_realm_zammad_accounts

      click_on 'John Doe'
      find('a', text: 'Sign out').click

      visit '/'
      expect(page).to have_current_route('login')
      find_by_id('app')
    end
  end

  describe "use custom user attribute 'uid' as uid_attribute" do
    before do
      saml_configure_zammad(saml_base_url:, saml_realm_zammad_descriptor:, uid_attribute: 'uid')
    end

    it 'is successful' do
      login_saml

      user = User.find_by(email: 'john.doe@saml.example.com')
      expect(user.login).to eq('5f8179df-db5e-415c-8090-6cc3634d86b6')

      logout_saml
    end
  end

  describe 'use unspecified (IDP provided) name identifier' do
    before do
      saml_configure_zammad(saml_base_url:, saml_realm_zammad_descriptor:, name_identifier_format: 'urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified')
    end

    it 'is successful' do
      login_saml

      user = User.find_by(email: 'john.doe@saml.example.com')
      expect(user.login).to eq('john.doe')

      logout_saml
    end
  end

  describe 'SAML logout without IDP SLO service URL' do
    before do
      saml_configure_zammad(saml_base_url:, saml_realm_zammad_descriptor:, idp_slo_service_url: false)
    end

    it 'is successful' do
      login_saml

      user = User.find_by(email: 'john.doe@saml.example.com')
      expect(user.login).to eq('john.doe@saml.example.com')

      logout_saml

      visit saml_realm_zammad_accounts
      expect(page).to have_text('John Doe')
    end
  end

  describe 'Mobile View', app: :mobile do
    before do
      skip 'Skip mobile tests enforced.' if ENV['SKIP_MOBILE_TESTS']
    end

    context 'when login is tested' do
      before do
        saml_configure_zammad(saml_base_url:, saml_realm_zammad_descriptor:)
      end

      it 'is successful' do
        login_saml(app: 'mobile')

        visit saml_realm_zammad_accounts
        click_on 'Actions'
        expect(page).to have_text('Sign out')
      end
    end

    context 'when logout is tested' do
      before do
        saml_configure_zammad(saml_base_url:, saml_realm_zammad_descriptor:)
      end

      it 'is successful' do
        login_saml(app: 'mobile')

        visit '/account', app: :mobile
        click_on('Sign out')

        wait.until do
          expect(page).to have_button('Sign in')
        end

        visit saml_realm_zammad_accounts
        expect(page).to have_text('Sign in')
      end
    end

    context 'when saml user already exists with agent role' do
      before do
        Setting.set('auth_third_party_auto_link_at_inital_login', true)
        create(:agent, email: 'john.doe@saml.example.com', login: 'john.doe', firstname: 'John', lastname: 'Doe')

        saml_configure_zammad(saml_base_url:, saml_realm_zammad_descriptor:)
      end

      it 'is successful' do
        login_saml(app: 'mobile')

        visit saml_realm_zammad_accounts
        click_on 'Actions'
        expect(page).to have_text('Sign out')
      end
    end

    context 'when logout is tested without IDP SLO service URL' do
      before do
        saml_configure_zammad(saml_base_url:, saml_realm_zammad_descriptor:, idp_slo_service_url: false)
      end

      it 'is successful' do
        login_saml(app: 'mobile')

        visit '/account', app: :mobile
        click_on('Sign out')

        wait.until do
          expect(page).to have_button('Sign in')
        end

        visit saml_realm_zammad_accounts
        click_on 'Actions'
        expect(page).to have_text('Sign out')
      end
    end

  end
end
