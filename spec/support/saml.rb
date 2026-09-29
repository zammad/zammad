# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module ZammadSpecSupportSAML

  def saml_configure_keycloak(zammad_saml_metadata:, saml_client_json:)
    token       = saml_keycloak_admin_token
    clients_url = "#{ENV['KEYCLOAK_BASE_URL']}/admin/realms/zammad/clients"

    # Force create Zammad client in Keycloak.
    clients = saml_keycloak_request!(:get, "#{clients_url}?clientId=#{CGI.escape(zammad_saml_metadata)}", {}, { json: true, bearer_token: token }).data
    clients.each do |client|
      saml_keycloak_request!(:delete, "#{clients_url}/#{client['id']}", {}, { bearer_token: token })
    end
    saml_keycloak_request!(:post, clients_url, JSON.parse(saml_client_json), { json: true, jsonParseDisable: true, bearer_token: token })
  end

  def saml_keycloak_admin_token
    response = saml_keycloak_request!(
      :post,
      "#{ENV['KEYCLOAK_BASE_URL']}/realms/master/protocol/openid-connect/token",
      {
        grant_type: 'password',
        client_id:  'admin-cli',
        username:   ENV['KC_BOOTSTRAP_ADMIN_USERNAME'],
        password:   ENV['KC_BOOTSTRAP_ADMIN_PASSWORD'],
      },
    )

    JSON.parse(response.body)['access_token']
  end

  def saml_keycloak_request!(method, url, params = {}, options = {})
    response = UserAgent.public_send(method, url, params, options)
    raise "Keycloak request #{method.upcase} #{url} failed: #{response.code} #{response.body}" if !response.success?

    response
  end

  def saml_configure_zammad(saml_base_url:, saml_realm_zammad_descriptor:, name_identifier_format: nil, uid_attribute: nil, idp_slo_service_url: true, security: nil)
    # Setup Zammad SAML authentication.
    response = UserAgent.get(saml_realm_zammad_descriptor)
    raise 'No Zammad realm descriptor found' if !response.success?

    match = response.body.match(%r{<ds:X509Certificate>(?<cert>.+)</ds:X509Certificate>})
    raise 'No X509Certificate found' if !match[:cert]

    auth_saml_credentials =
      {
        display_name:           'SAML',
        idp_sso_target_url:     "#{saml_base_url}/realms/zammad/protocol/saml",
        idp_cert:               "-----BEGIN CERTIFICATE-----\n#{match[:cert]}\n-----END CERTIFICATE-----",
        name_identifier_format: name_identifier_format || 'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress',
      }
    auth_saml_credentials[:idp_slo_service_url] = "#{saml_base_url}/realms/zammad/protocol/saml" if idp_slo_service_url
    auth_saml_credentials[:uid_attribute] = uid_attribute if uid_attribute

    if security.present?
      auth_saml_credentials[:security]           = 'on'
      auth_saml_credentials[:certificate]        = security[:cert]
      auth_saml_credentials[:private_key]        = security[:key]
      auth_saml_credentials[:private_key_secret] = ''
    end

    # Disable setting validation. We have an explicit test for this.
    setting = Setting.find_by(name: 'auth_saml_credentials')
    setting.state_current = { value: auth_saml_credentials }
    setting.save!(validate: false)

    Setting.set('auth_saml', true)
  end

  def saml_login_keycloak
    find_by_id('kc-form')
    expect(page).to have_current_path(%r{/realms/zammad/protocol/saml\?SAMLRequest=.+})
    expect(page).to have_css('#kc-form-login')

    within '#kc-form-login' do
      fill_in 'username', with: 'john.doe'
      fill_in 'password', with: 'test'

      click_on 'Sign In'
    end

    expect(page).to have_no_text('Sign In')
  end

end

RSpec.configure do |config|
  config.include ZammadSpecSupportSAML, integration_standalone: :saml
end
