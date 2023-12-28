# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Service::User::PasswordReset::Deprecated::Send < Service::User::PasswordReset::Send

  attr_reader :username

  def initialize(username:)
    super(username: username)

    @path = {
      reset: '#password_reset_verify/'
    }
  end
end
