# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Auth

  attr_reader :user, :password, :auth_user

  delegate :user, to: :auth_user

  attr_accessor :increase_login_failed_attempts

  BRUTE_FORCE_SLEEP = 1.second

  # Initializes a Auth object for the given user.
  #
  # @param username [String] the user name for the user object which needs an authentication.
  #
  # @example
  #  auth = Auth.new('admin@example.com', 'some+password')
  def initialize(username, password)
    @auth_user = username.present? ? Auth::User.new(username) : nil
    @password = password
    @increase_login_failed_attempts = false
  end

  # Validates the given credentials for the user to the configured auth backends which should
  # be performed.
  #
  # @return [Boolean] true if the user was authenticated, otherwise false.
  def valid?
    # Wrap in a lock to synchronize concurrent requests.
    validated = auth_user&.user&.with_lock do
      next false if !auth_user.can_login?
      next true if backends.valid?

      auth_user.increase_login_failed if increase_login_failed_attempts
      false
    end

    if validated
      auth_user.update_last_login
      return true
    end

    avoid_brute_force_attack
    false
  end

  private

  # Sleep for a second to avoid brute force attacks.
  def avoid_brute_force_attack
    sleep BRUTE_FORCE_SLEEP
  end

  def backends
    Auth::Backend.new(self)
  end
end
