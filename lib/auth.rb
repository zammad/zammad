# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Auth

  attr_reader :user, :password, :auth_user, :two_factor_method, :two_factor_payload, :only_verify_password

  delegate :user, to: :auth_user

  attr_accessor :increase_login_failed_attempts

  BRUTE_FORCE_SLEEP = 1.second

  # Initializes a Auth object for the given user.
  #
  # @param username [String] the user name for the user object which needs an authentication.
  #
  # @example
  #  auth = Auth.new('admin@example.com', 'some+password')
  def initialize(username, password, two_factor_method: nil, two_factor_payload: nil, only_verify_password: false)
    @auth_user                      = username.present? ? Auth::User.new(username) : nil
    @password                       = password
    @two_factor_payload             = two_factor_payload
    @two_factor_method              = two_factor_method
    @increase_login_failed_attempts = false
    @only_verify_password           = only_verify_password

    return if !@two_factor_payload.is_a?(Hash)

    @two_factor_payload = @two_factor_payload.symbolize_keys
  end

  # Validates the given credentials for the user to the configured auth backends which should
  # be performed.
  #
  # @return true if the user was authenticated, otherwise it raises an Exception.
  def valid!

    if verify_credentials!
      auth_user.update_last_login if !only_verify_password
      return true
    end

    wait_and_raise Auth::Error::AuthenticationFailed
  end

  private

  def verify_credentials!
    # Wrap in a lock to synchronize concurrent requests.
    auth_user&.user&.with_lock do
      next false if !auth_user.can_login?

      if !backends.valid?
        # Failed log-in attempts are only recorded if the password backend requests so.
        auth_user.increase_login_failed if increase_login_failed_attempts && !only_verify_password
        next false
      end
      verify_two_factor!
    end
  end

  def verify_two_factor!
    return true if only_verify_password
    return true if !auth_user.requires_two_factor?

    if two_factor_method.blank?
      raise Auth::Error::TwoFactorRequired, auth_user
    end

    auth_user.two_factor_payload_valid?(two_factor_method, two_factor_payload) || wait_and_raise(Auth::Error::TwoFactorFailed)
  end

  def wait_and_raise(...)
    # Sleep for a second to avoid brute force attacks.
    sleep BRUTE_FORCE_SLEEP
    raise(...)
  end

  def backends
    Auth::Backend.new(self)
  end
end
