# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

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
    ensure_not_import_mode!

    Service::CheckFeatureEnabled.new(name: 'user_lost_password').execute

    result = ::User.password_reset_new_token(username)

    # Result is always positive to avoid leaking of existing user accounts.
    return true if !result || !result[:token]

    result[:url] = "#{Setting.get('http_type')}://#{Setting.get('fqdn')}/#{@path[:reset]}#{result[:token].token}"

    NotificationFactory::Mailer.notification(
      template: 'password_reset',
      user:     result[:user],
      objects:  result,
    )

    true
  end

  private

  def ensure_not_import_mode!
    return if !Setting.get('import_mode')

    Rails.logger.error "Could not send password reset email to user #{username} because import_mode setting is on."
    raise Exceptions::UnprocessableEntity, __('The email could not be sent to the user because import_mode setting is on.')
  end
end
