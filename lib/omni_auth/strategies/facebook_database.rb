# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

begin
  require 'omniauth-facebook'

  class OmniAuth::Strategies::FacebookDatabase < OmniAuth::Strategies::Facebook
    option :name, 'facebook'

    def initialize(app, *args, &)

      # database lookup
      config  = Setting.get('auth_facebook_credentials') || {}
      args[0] = config['app_id']
      args[1] = config['app_secret']
      super
    end

  end
rescue LoadError => e
  Rails.logger.debug { "OmniAuth: skipping facebook strategy (#{e.message})" }
end
