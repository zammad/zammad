# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Service::User::PasswordReset::Deprecated::Send < Service::User::PasswordReset::Send

  attr_reader :username

  def initialize(username:)
    super

    @path = {
      reset: '#password_reset_verify/'
    }
  end
end
