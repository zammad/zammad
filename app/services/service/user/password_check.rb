# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

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

    true
  rescue Auth::Error::AuthenticationFailed
    false
  end
end
