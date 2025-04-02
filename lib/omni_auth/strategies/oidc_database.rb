# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class OmniAuth::Strategies::OidcDatabase < OmniAuth::Strategies::OpenIDConnect
  option :name, 'openid_connect'

  def self.setup
    auth_openid_connect_credentials = Setting.get('auth_openid_connect_credentials') || {}

    http_type = Setting.get('http_type')
    fqdn      = Setting.get('fqdn')

    client_options = {
      identifier:   auth_openid_connect_credentials['identifier'],
      redirect_uri: "#{http_type}://#{fqdn}/auth/openid_connect/callback",
    }

    auth_openid_connect_credentials['scope'] = %i[openid email profile] if auth_openid_connect_credentials['scope'].blank?
    auth_openid_connect_credentials['scope'] = auth_openid_connect_credentials['scope'].split.map(&:to_sym) if auth_openid_connect_credentials['scope'].is_a?(String)

    auth_openid_connect_credentials.compact_blank.merge(
      discovery:      true,
      response_type:  :code,
      pkce:           ActiveModel::Type::Boolean.new.cast(auth_openid_connect_credentials['pkce']),
      client_options:,
    )
  end

  def self.destroy_session(env, session)
    session.delete('oidc_id_token')

    @_current_user = nil
    env['rack.session.options'][:expire_after] = nil

    session.destroy
  end

  def initialize(app, *args, &)
    args[0] = self.class.setup

    super
  end

  def decode_logout_token(logout_token)
    decode_id_token(logout_token)
  end
end
