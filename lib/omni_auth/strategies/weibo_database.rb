# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class OmniAuth::Strategies::WeiboDatabase < OmniAuth::Strategies::Weibo
  include OmniAuth::Strategies::DatabaseSettings

  option :name, 'weibo'

  def self.setup
    config = Setting.get('auth_weibo_credentials') || {}

    {
      client_id:     config['client_id'],
      client_secret: config['client_secret'],
    }
  end
end
