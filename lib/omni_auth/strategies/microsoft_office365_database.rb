# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'jwt'

class OmniAuth::Strategies::MicrosoftOffice365Database < OmniAuth::Strategies::MicrosoftOffice365
  include OmniAuth::Strategies::DatabaseSettings

  option :name, 'microsoft_office365'

  # Override the gem's DEFAULT_SCOPE ("openid User.Read Contacts.Read") to drop
  # the Contacts.Read permission. Setting the scope option here makes the gem
  # skip its `params[:scope] ||= DEFAULT_SCOPE` fallback.
  option :scope, 'openid User.Read'

  def self.setup
    config = Setting.get('auth_microsoft_office365_credentials') || {}
    tenant = config['app_tenant'].presence || 'common'

    {
      client_id:      config['app_id'],
      client_secret:  config['app_secret'],
      client_options: {
        authorize_url: "/#{tenant}/oauth2/v2.0/authorize",
        token_url:     "/#{tenant}/oauth2/v2.0/token",
      },
    }
  end

  # The gem's raw_info only calls the Graph /me REST endpoint, which never
  # carries ID token claims such as "xms_edov" (Microsoft's "Email Domain Owner
  # Verified" claim, the recommended signal for safely trusting an email
  # address from a multi-tenant "/common" app registration). We already
  # request the "openid" scope, so the ID token is returned alongside the
  # access token - decode it and expose its claims as their own extra key
  # (OmniAuth merges each ancestor's "extra" block automatically, so this
  # doesn't need to - and, being defined at the class body level rather than
  # inside a regular method, *can't* - call super) for
  # Authorization::Provider::MicrosoftOffice365#email_verified? to read.
  extra do
    id_token = access_token.params['id_token']
    id_token.present? ? { 'id_token_claims' => JWT.decode(id_token, nil, false).first } : {}
  rescue JWT::DecodeError => e
    Rails.logger.warn { "Failed to decode MS365 ID token: #{e.message}" }
    {}
  end
end
