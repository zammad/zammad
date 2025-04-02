# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::User::ChangePassword < Service::Base

  attr_reader :user, :current_password, :new_password

  def initialize(user:, current_password:, new_password:)
    super()

    @user = user
    @current_password = current_password
    @new_password = new_password
  end

  def execute
    PasswordHash.verified!(@user.password, @current_password)
    PasswordPolicy.new(@new_password).valid!

    @user.update!(password: @new_password)
    notify_user

    true
  end

  private

  def notify_user
    return if @user.email.blank?

    NotificationFactory::Mailer.notification(
      template: 'password_change',
      user:     @user,
      objects:  {
        user: @user,
      }
    )
  end
end
