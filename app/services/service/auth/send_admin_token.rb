# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Service::Auth::SendAdminToken < Service::Base
  include Service::Auth::Concerns::CheckPasswordLogin

  attr_reader :login

  def initialize(login:)
    super()
    @login = login
    @path = 'desktop/login?token='
  end

  def execute
    raise Exceptions::UnprocessableEntity, __('This feature is not enabled.') if password_login?

    result = ::User.admin_password_auth_new_token(login)

    return false if !result || !result[:token]

    raise Exceptions::UnprocessableEntity, __('Unable to send admin password auth email.') if !result[:user] || result[:user].email.blank?

    result[:url] = "#{Setting.get('http_type')}://#{Setting.get('fqdn')}/#{@path}#{result[:token].token}"

    NotificationFactory::Mailer.notification(
      template: 'admin_password_auth',
      user:     result[:user],
      objects:  result
    )

    true
  end
end
