# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Service::User::PasswordReset::Update < Service::Base

  attr_reader :token, :password

  def initialize(token:, password:)
    super()

    @token = token
    @password = password
  end

  def execute
    Service::CheckFeatureEnabled.new(name: 'user_lost_password').execute

    PasswordPolicy.new(password).valid!

    user = ::User.password_reset_via_token(token, password)
    raise InvalidTokenError if !user
    raise EmailError if user.email.blank?

    NotificationFactory::Mailer.notification(
      template: 'password_change',
      user:     user,
      objects:  {
        user: user,
      }
    )

    user
  end

  class InvalidTokenError < StandardError
    def initialize
      super(__('The provided token is invalid.'))
    end
  end

  class EmailError < StandardError
    def initialize
      super(__('The email could not be sent to the user.'))
    end
  end
end
