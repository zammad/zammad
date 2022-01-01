# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class GoogleOauth2Database < OmniAuth::Strategies::GoogleOauth2
  option :name, 'google_oauth2'

  def initialize(app, *args, &block)

    # database lookup
    config  = Setting.get('auth_google_oauth2_credentials') || {}
    args[0] = config['client_id']
    args[1] = config['client_secret']
    super
  end

end
