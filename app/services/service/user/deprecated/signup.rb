# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::User::Deprecated::Signup < Service::User::Signup

  attr_reader :user_data, :resend

  def initialize(user_data:, resend: false)
    super

    @path = {
      signup: '#email_verify/',
      taken:  '#password_reset_verify/'
    }
  end
end
