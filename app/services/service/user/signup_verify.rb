# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::User::SignupVerify < Service::Base
  # Current user is used in this serivce, but it is optional.
  # Thus no need for requires_current_user!

  attr_reader :token

  def initialize(token:)
    @token = token
  end

  def execute
    Service::CheckFeatureEnabled.execute(name: 'user_create_account')

    user = ::User.signup_verify_via_token(token, current_user)

    raise InvalidTokenError if !user

    user
  end

  class InvalidTokenError < StandardError
    def initialize
      super(__('The provided token is invalid.'))
    end
  end
end
