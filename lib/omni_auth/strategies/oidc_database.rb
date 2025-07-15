# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class OmniAuth::Strategies::OidcDatabase < OmniAuth::Strategies::OpenIDConnect
  option :name, 'openid_connect'

  def self.setup
    credentials = Setting.get('auth_openid_connect_credentials') || {}

    credentials.compact_blank.merge(
      response_type: :code,
      discovery:      discovery?(credentials),
      pkce:           pkce?(credentials),
      scope:          scope(credentials),
      client_options: client_options(credentials)
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

  private_class_method

  def self.discovery?(credentials)
    ActiveModel::Type::Boolean.new.cast(credentials['discovery'])
  end

  def self.pkce?(credentials)
    ActiveModel::Type::Boolean.new.cast(credentials['pkce'])
  end

  def self.scope(credentials)
    raw = credentials['scope'].presence || %w[openid email profile]
    raw = raw.split if raw.is_a?(String)
    raw.map(&:to_sym)
  end

  def self.client_options(credentials)
    opts = base_client_options(credentials)
    # If discovery is enabled, we just return the base options
    return opts if discovery?(credentials)
    # If discovery is disabled, we need to merge the base options with the endpoint options
    opts.merge(endpoint_client_options(credentials))
  end

  def self.base_client_options(credentials)
    http_type = Setting.get('http_type')
    fqdn = Setting.get('fqdn')
    redirect_uri = "#{http_type}://#{fqdn}/auth/openid_connect/callback"
    identifier, issuer = credentials.values_at('identifier', 'issuer')
    { identifier:,  issuer:, redirect_uri: }
  end

  def self.endpoint_client_options(credentials)
    # If the issuer is not set, we cannot extract the endpoints
    return {} if credentials.blank? or credentials['issuer'].blank?
    # Extract the scheme, user, host, and port from the issuer URL
    # This is necessary to ensure we have the correct URL components for the client options
    # The URI.split method returns an array with the following structure:
    # [scheme, user, host, port, path, query, fragment].
    #
    # We only need the scheme, host, and port for the client options.
    scheme, _user, host, port, *_ = URI.split(credentials['issuer'])

    credentials
      .slice('secret', 'authorization_endpoint', 'token_endpoint', 'userinfo_endpoint', 'jwks_uri')
      .symbolize_keys
      .merge({ scheme:, host:, port: })
  end
end