# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class GithubDatabase < OmniAuth::Strategies::GitHub
  option :name, 'github'

  def initialize(app, *args, &)

    # database lookup
    config  = Setting.get('auth_github_credentials') || {}
    args[0] = config['app_id']
    args[1] = config['app_secret']
    super
  end

end
