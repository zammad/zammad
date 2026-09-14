# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::User::PasswordReset::Send < Service::Base
  include Service::Concerns::HoldsResponseDeadline

  attr_reader :username

  def initialize(username:)
    @username = username
    @path = {
      reset: 'desktop/reset-password/verify/'
    }
  end

  def execute
    ensure_not_import_mode!

    Service::CheckFeatureEnabled.execute(name: 'user_lost_password')

    # Answers after a fixed duration, whatever the part below has to do.
    with_response_deadline do
      result = ::User.password_reset_new_token(username)

      # Result is always positive to avoid leaking of existing user accounts.
      next true if !result || !result[:token]

      # Delivered in the background, so that the request does not wait for the SMTP server.
      NotificationMailerJob.perform_later(
        template: 'password_reset',
        user:     result[:user],
        objects:  result,
        url_path: @path[:reset],
      )

      true
    end
  end

  private

  def ensure_not_import_mode!
    return if !Setting.get('import_mode')

    Rails.logger.error "Could not send password reset email to user #{username} because import_mode setting is on."
    raise Exceptions::UnprocessableContent, __('The email could not be sent to the user because import_mode setting is on.')
  end
end
