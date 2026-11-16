# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class OmniAuth::Strategies::GithubDatabase < OmniAuth::Strategies::GitHub
  include OmniAuth::Strategies::DatabaseSettings

  option :name, 'github'

  def self.setup
    config = Setting.get('auth_github_credentials') || {}

    {
      client_id:     config['app_id'],
      client_secret: config['app_secret'],
    }
  end
end
