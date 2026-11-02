# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class OmniAuth::Strategies::GoogleOauth2Database < OmniAuth::Strategies::GoogleOauth2
  include OmniAuth::Strategies::DatabaseSettings

  option :name, 'google_oauth2'

  def self.setup
    config = Setting.get('auth_google_oauth2_credentials') || {}

    {
      client_id:     config['client_id'],
      client_secret: config['client_secret'],
    }
  end
end
