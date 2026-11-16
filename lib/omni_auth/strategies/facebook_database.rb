# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class OmniAuth::Strategies::FacebookDatabase < OmniAuth::Strategies::Facebook
  include OmniAuth::Strategies::DatabaseSettings

  option :name, 'facebook'

  def self.setup
    config = Setting.get('auth_facebook_credentials') || {}

    {
      client_id:     config['app_id'],
      client_secret: config['app_secret'],
    }
  end
end
