# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Auth
  include ApplicationLib

=begin

checks if a given user can login. Checks for
 - valid user
 - active state
 - max failed logins

  result = Auth.can_login?(user)

returns

  result = true | false

=end

  def self.can_login?(user)
    return false if !user.is_a?(User)
    return false if !user.active?

    return true if !user.max_login_failed?

    Rails.logger.info "Max login failed reached for user #{user.login}."

    false
  end

=begin

checks if a given user and password match against multiple auth backends
 - valid user
 - active state
 - max failed logins

  result = Auth.valid?(user, password)

returns

  result = true | false

=end

  def self.valid?(user, password)
    # try to login against configure auth backends
    backends.any? do |config|
      next if !backend_validates?(
        config:   config,
        user:     user,
        password: password,
      )

      Rails.logger.info "Authentication against #{config[:adapter]} for user #{user.login} ok."

      # remember last login date
      user.update_last_login

      true
    end
  end

=begin

returns a list of all Auth backend configurations

  result = Auth.backends

returns

  result = [
    {
      adapter: 'Auth::Internal',
    },
    {
      adapter: 'Auth::Developer',
    },
    ...
  ]

=end

  def self.backends

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
    Setting.where(area: 'Security::Authentication').each do |setting|
      next if setting.state_current[:value].blank?

      config.push setting.state_current[:value]
    end

    config
  end

  def self.backend_validates?(config:, user:, password:)
    return false if !config[:adapter]

    instance = config[:adapter].constantize.new(config)

    instance.valid?(user, password)
  end
  private_class_method :backend_validates?
end
