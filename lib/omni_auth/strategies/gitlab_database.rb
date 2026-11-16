# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class OmniAuth::Strategies::GitLabDatabase < OmniAuth::Strategies::GitLab
  include OmniAuth::Strategies::DatabaseSettings

  option :name, 'gitlab'

  def self.setup
    config = Setting.get('auth_gitlab_credentials') || {}

    {
      client_id:      config['app_id'],
      client_secret:  config['app_secret'],
      client_options: config.symbolize_keys,
    }
  end
end
