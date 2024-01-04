# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class OmniAuth::Strategies::GitLabDatabase < OmniAuth::Strategies::GitLab
  option :name, 'gitlab'

  def initialize(app, *args, &)

    # database lookup
    config  = Setting.get('auth_gitlab_credentials') || {}
    args[0] = config['app_id']
    args[1] = config['app_secret']
    args[2][:client_options] = args[2][:client_options].merge(config.symbolize_keys)
    super
  end

end
