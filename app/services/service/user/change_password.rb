# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::User::ChangePassword < Service::Base
  requires_current_user!

  attr_reader :current_password, :new_password

  def initialize(current_password:, new_password:)
    @current_password = current_password
    @new_password = new_password
  end

  def execute
    PasswordHash.verified!(current_user.password, current_password)
    PasswordPolicy.new(new_password).valid!

    current_user.update!(password: new_password)
    notify_user

    true
  end

  private

  def notify_user
    return if current_user.email.blank?

    NotificationFactory::Mailer.notification(
      template: 'password_change',
      user:     current_user,
      objects:  {
        user: current_user,
      }
    )
  end
end
