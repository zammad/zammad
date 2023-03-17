# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Auth
  class User < SimpleDelegator

    attr_reader :user

    def initialize(username)
      @user = ::User.identify(username)
      super(@user)
    end

    # Checks if a given user can login. Check for the following criteria:
    # * valid user
    # * user is active
    # * user has not reached the maximum of failed login tries
    #
    # @return [Boolean] true if the user can login, false otherwise.
    def can_login?
      return false if !exists?
      return false if !active?

      !max_login_failed?
    end

    # Increase the current failed login count for the user.
    def increase_login_failed
      self.login_failed += 1
      save!
    end

    private

    # Checks if a user has reached the maximum of failed login tries.
    #
    # @return [Boolean] true if the user has reached the maximum of failed login tries, otherwise false.
    def max_login_failed?
      max_login_failed = Setting.get('password_max_login_failed').to_i
      return false if login_failed <= max_login_failed

      Rails.logger.info "Max login failed reached for user #{login}."
      true
    end

    # Checks if a valid user exists.
    #
    # @return [Boolean] true if a valid user exists, otherwise false.
    def exists?
      present? && __getobj__.is_a?(::User)
    end
  end
end
