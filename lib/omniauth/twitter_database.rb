# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class TwitterDatabase < OmniAuth::Strategies::Twitter
  option :name, 'twitter'

  def initialize(app, *args, &)

    # database lookup
    config  = Setting.get('auth_twitter_credentials') || {}
    args[0] = config['key']
    args[1] = config['secret']
    super
  end

end
