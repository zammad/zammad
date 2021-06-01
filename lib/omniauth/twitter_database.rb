# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class TwitterDatabase < OmniAuth::Strategies::Twitter
  option :name, 'twitter'

  def initialize(app, *args, &block)

    # database lookup
    config  = Setting.get('auth_twitter_credentials') || {}
    args[0] = config['key']
    args[1] = config['secret']
    super
  end

end
