# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Auth
  class User < SimpleDelegator

    attr_reader :user, :two_factor

    def initialize(username)
      @user = ::User.identify(username)
      @two_factor = Auth::TwoFactor.new(@user)
      super(@user)
    end

    def can_login?
      exists? && active? && !max_login_failed?
    end

    def increase_login_failed
      self.login_failed += 1
      save!
    end

    def requires_two_factor?
      two_factor.user_configured?
    end

    def two_factor_payload_valid?(two_factor_method, two_factor_payload)
      two_factor.verify?(two_factor_method, two_factor_payload)
    end

    private

    def max_login_failed?
      max_login_failed = Setting.get('password_max_login_failed').to_i
      return false if login_failed <= max_login_failed

      Rails.logger.info "Max login failed reached for user #{login}."
      true
    end

    def exists?
      present? && __getobj__.is_a?(::User)
    end
  end
end
