# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Delivers the password change notification.
class Service::User::SendPasswordChangeNotification < Service::Base
  attr_reader :user, :recipient

  def initialize(user:, recipient: user)
    @user = user
    @recipient = recipient
  end

  def execute
    NotificationFactory::Mailer.notification(
      template: 'password_change',
      user:     recipient,
      objects:  {
        user: user,
      }
    )
  end
end
