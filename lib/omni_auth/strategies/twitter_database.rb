# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class OmniAuth::Strategies::TwitterDatabase < OmniAuth::Strategies::Twitter
  include OmniAuth::Strategies::DatabaseSettings

  option :name, 'twitter'

  def self.setup
    config = Setting.get('auth_twitter_credentials') || {}

    {
      consumer_key:    config['key'],
      consumer_secret: config['secret'],
    }
  end
end
