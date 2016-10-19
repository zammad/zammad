# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Sso
  include ApplicationLib

=begin

authenticate user via username and password

  result = Sso.check( params )

returns

  result = user_model # if authentication was successfully

=end

  def self.check(params)

    # use std. auth backends
    config = [
      {
        adapter: 'Sso::Env',
      },
    ]

    # added configured backends
    Setting.where( area: 'Security::SSO' ).each { |setting|
      if setting.state_current[:value]
        config.push setting.state_current[:value]
      end
    }

    # try to login against configure auth backends
    user_auth = nil
    config.each { |config_item|
      next if !config_item[:adapter]

      # load backend
      backend = load_adapter( config_item[:adapter] )
      next if !backend

      user_auth = backend.check( params, config_item )

      # auth not ok
      next if !user_auth

      Rails.logger.info "Authentication against #{config_item[:adapter]} for user #{user_auth.login} ok."

      # remember last login date
      user_auth.update_last_login

      return user_auth
    }
    nil
  end
end
