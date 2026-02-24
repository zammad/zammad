# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

begin
  require 'omniauth-twitter'

  class OmniAuth::Strategies::TwitterDatabase < OmniAuth::Strategies::Twitter
    option :name, 'twitter'

    def initialize(app, *args, &)

      # database lookup
      config  = Setting.get('auth_twitter_credentials') || {}
      args[0] = config['key']
      args[1] = config['secret']
      super
    end

  end
rescue LoadError => e
  Rails.logger.debug { "OmniAuth: skipping twitter strategy (#{e.message})" }
end
