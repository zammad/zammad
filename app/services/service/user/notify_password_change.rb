# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Notifies the account owner when somebody else set their password. Password
# changes performed by the owner themselves are notified by the flow that
# performs them (Service::User::ChangePassword, Service::User::PasswordReset::Update).
class Service::User::NotifyPasswordChange < Service::Base
  requires_current_user!

  attr_reader :user

  def initialize(user:)
    @user = user
  end

  def execute
    return if !user.saved_change_to_password?
    return if user.id == current_user.id

    deliver_notification(user)

    # A single update can change email and password at once - without this the
    # previous address, and with it the previous owner, is never informed.
    deliver_notification(user_with_previous_email) if user.saved_change_to_email?
  end

  private

  def deliver_notification(recipient)
    return if recipient.email.blank?

    Service::User::SendPasswordChangeNotification.execute(user: user, recipient: recipient)
  rescue => e
    Rails.logger.error "Unable to notify #{recipient.email} about the password change: #{e.message}"
  end

  # NotificationFactory::Mailer takes the address from the record it is given.
  def user_with_previous_email
    user.dup.tap { |copy| copy.email = user.email_previously_was }
  end
end
