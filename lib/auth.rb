# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Auth

  attr_reader :user, :password, :auth_user

  delegate :user, to: :auth_user

  attr_accessor :increase_login_failed_attempts

  # Initializes a Auth object for the given user.
  #
  # @param username [String] the user name for the user object which needs an authentication.
  #
  # @example
  #  auth = Auth.new('admin@example.com', 'some+password')
  def initialize(username, password)
    @lookup_backend_instance = {}

    @auth_user = username.present? ? Auth::User.new(username) : nil
    @password = password

    @increase_login_failed_attempts = false
  end

  # Validates the given credentials for the user to the configured auth backends which should
  # be performed.
  #
  # @return [Boolean] true if the user was authenticated, otherwise false.
  def valid?
    if !auth_user || !auth_user.can_login?
      avoid_brute_force_attack

      return false
    end

    if backends.valid?
      auth_user.update_last_login
      return true
    end

    avoid_brute_force_attack

    auth_user.increase_login_failed if increase_login_failed_attempts
    false
  end

  private

  # Sleep for a second to avoid brute force attacks.
  def avoid_brute_force_attack
    sleep 1
  end

  def backends
    Auth::Backend.new(self)
  end
end
