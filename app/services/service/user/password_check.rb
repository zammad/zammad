# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::User::PasswordCheck < Service::Base
  attr_reader :user, :password

  def initialize(user:, password:)
    super()

    @user     = user
    @password = password
  end

  def execute
    Auth
      .new(user.login, password, only_verify_password: true)
      .valid!

    token = Token.create(action: 'PasswordCheck', user_id: user.id, persistent: false, expires_at: 1.hour.from_now)

    {
      success: true,
      token:   token.token,
    }
  rescue Auth::Error::AuthenticationFailed
    {
      success: false,
    }
  end
end
