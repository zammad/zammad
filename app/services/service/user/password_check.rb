# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::User::PasswordCheck < Service::Base
  requires_current_user!

  attr_reader :password

  def initialize(password:)
    @password = password
  end

  def execute
    Auth
      .new(current_user.login, password, only_verify_password: true, skip_login_failed_tracking: true)
      .valid!

    token = Token.create(action: 'PasswordCheck', user_id: current_user.id, persistent: false, expires_at: 1.hour.from_now)

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
