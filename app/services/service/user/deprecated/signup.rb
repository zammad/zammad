# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Service::User::Deprecated::Signup < Service::User::Signup

  attr_reader :user_data, :resend

  def initialize(user_data:, resend: false)
    super(user_data: user_data, resend: resend)

    @path = {
      signup: '#email_verify/',
      taken:  '#password_reset_verify/'
    }
  end
end
