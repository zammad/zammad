# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module ZammadSpecSupportOIDC
  OIDC_CLIENT_ID = 'zammad-oidc'.freeze

  # Returns the ID of the client, e.g. to assign client roles to the user.
  def oidc_configure_keycloak(zammad_base_url:)
    client_json = Rails.root.join('test/data/oidc/zammad-client.json').read.gsub('#ZAMMAD_BASE_URL', zammad_base_url)

    keycloak_recreate_client(client_id: OIDC_CLIENT_ID, client_json:)
  end

  def oidc_configure_zammad
    Setting.set('auth_openid_connect_credentials', {
                  display_name: 'OpenID Connect',
                  identifier:   OIDC_CLIENT_ID,
                  issuer:       "#{ENV['KEYCLOAK_BASE_URL']}/realms/zammad",
                  pkce:         true,
                })
    Setting.set('auth_openid_connect', true)
  end

  def oidc_login_keycloak
    keycloak_login(path: %r{/realms/zammad/protocol/openid-connect/auth\?.+})
  end
end

RSpec.configure do |config|
  config.include ZammadSpecSupportOIDC, integration_standalone: :oidc

  # The discovery of the openid_connect gem only speaks HTTPS, while the Keycloak service is served via HTTP.
  config.around(:each, integration_standalone: :oidc) do |example|
    url_builder = SWD.url_builder
    SWD.url_builder = URI::HTTP if ENV['KEYCLOAK_BASE_URL'].to_s.start_with?('http://')

    example.run
  ensure
    SWD.url_builder = url_builder
  end
end
