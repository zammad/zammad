# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Service::User::PasswordReset::Send < Service::Base

  attr_reader :username

  def initialize(username:)
    super()
    @username = username
    @path = {
      reset: 'desktop/reset-password/verify/'
    }
  end

  def execute
    Service::CheckFeatureEnabled.new(name: 'user_lost_password').execute

    result = ::User.password_reset_new_token(username)

    # Result is always positive to avoid leaking of existing user accounts.
    return true if !result || !result[:token]

    raise EmailError if !result[:user] || result[:user].email.blank?

    result[:url] = "#{Setting.get('http_type')}://#{Setting.get('fqdn')}/#{@path[:reset]}#{result[:token].token}"

    NotificationFactory::Mailer.notification(
      template: 'password_reset',
      user:     result[:user],
      objects:  result,
    )

    true
  end

  class EmailError < StandardError
    def initialize
      super(__('The email could not be sent to the user.'))
    end
  end
end
