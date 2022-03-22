# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class SamlDatabase < OmniAuth::Strategies::SAML
  option :name, 'saml'

  def initialize(app, *args, &block)

    http_type = Setting.get('http_type')
    fqdn      = Setting.get('fqdn')

    # Use meta URL as entity id/issues as it is best practice.
    # See: https://community.zammad.org/t/saml-oidc-third-party-authentication/2533/13
    entity_id                      = "#{http_type}://#{fqdn}/auth/saml/metadata"
    assertion_consumer_service_url = "#{http_type}://#{fqdn}/auth/saml/callback"

    config  = Setting.get('auth_saml_credentials') || {}
    options = config.compact_blank
      .merge(
        assertion_consumer_service_url: assertion_consumer_service_url,
        issuer:                         entity_id,
      )

    args[0] = options

    super
  end

end
