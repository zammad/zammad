# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Service::User::PasswordReset::Verify < Service::Base

  attr_reader :token

  def initialize(token:)
    super()
    @token = token
  end

  def execute
    Service::CheckFeatureEnabled.new(name: 'user_lost_password').execute

    user = ::User.by_reset_token(token)
    raise InvalidTokenError if !user

    user
  end

  class InvalidTokenError < StandardError
    def initialize
      super(__('The provided token is invalid.'))
    end
  end
end
