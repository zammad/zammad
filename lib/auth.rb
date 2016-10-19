# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Auth
  include ApplicationLib

=begin

authenticate user via username and password

  result = Auth.check(username, password, user)

returns

  result = user_model # if authentication was successfully

=end

  def self.check(username, password, user)

    # use std. auth backends
    config = [
      {
        adapter: 'Auth::Internal',
      },
      {
        adapter: 'Auth::Developer',
      },
    ]

    # added configured backends
    Setting.where(area: 'Security::Authentication').each { |setting|
      if setting.state_current[:value]
        config.push setting.state_current[:value]
      end
    }

    # try to login against configure auth backends
    user_auth = nil
    config.each { |config_item|
      next if !config_item[:adapter]

      # load backend
      backend = load_adapter(config_item[:adapter])
      next if !backend

      user_auth = backend.check(username, password, config_item, user)

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
