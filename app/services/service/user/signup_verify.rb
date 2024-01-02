# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Service::User::SignupVerify < Service::Base

  attr_reader :token, :current_user

  def initialize(token:, current_user: nil)
    super()
    @token = token
    @current_user = current_user
  end

  def execute
    Service::CheckFeatureEnabled.new(name: 'user_create_account').execute

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
