# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Service::Auth::SendAdminToken < Service::Base
  include Service::Auth::Concerns::CheckAdminPasswordAuth

  attr_reader :login

  def initialize(login:)
    super()
    @login = login
    @path = 'desktop/login?token='
  end

  def execute
    admin_password_auth!

    result = ::User.admin_password_auth_new_token(login)
    raise TokenError if !result || !result[:token]
    raise EmailError if !result[:user] || result[:user].email.blank?

    result[:url] = "#{Setting.get('http_type')}://#{Setting.get('fqdn')}/#{@path}#{result[:token].token}"
    NotificationFactory::Mailer.notification(
      template: 'admin_password_auth',
      user:     result[:user],
      objects:  result
    )

    true
  end

  class TokenError < StandardError
    def initialize
      super(__('Unable to create token for the user.'))
    end
  end

  class EmailError < StandardError
    def initialize
      super(__('Unable to send email to the user.'))
    end
  end
end
