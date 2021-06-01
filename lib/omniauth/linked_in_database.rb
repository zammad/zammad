# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class LinkedInDatabase < OmniAuth::Strategies::LinkedIn
  option :name, 'linkedin'

  def initialize(app, *args, &block)

    # database lookup
    config  = Setting.get('auth_linkedin_credentials') || {}
    args[0] = config['app_id']
    args[1] = config['app_secret']
    super
  end

end
