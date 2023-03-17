# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class WeiboDatabase < OmniAuth::Strategies::Weibo
  option :name, 'weibo'

  def initialize(app, *args, &)

    # database lookup
    config  = Setting.get('auth_weibo_credentials') || {}
    args[0] = config['client_id']
    args[1] = config['client_secret']
    super
  end

end
