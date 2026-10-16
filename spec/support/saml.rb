# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module ZammadSpecSupportSAML

  # Returns the ID of the client, e.g. to assign client roles to the user.
  def saml_configure_keycloak(zammad_saml_metadata:, saml_client_json:)
    keycloak_recreate_client(client_id: zammad_saml_metadata, client_json: saml_client_json)
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
    keycloak_login(path: %r{/realms/zammad/protocol/saml\?SAMLRequest=.+})
  end

end

RSpec.configure do |config|
  config.include ZammadSpecSupportSAML, integration_standalone: :saml
end
