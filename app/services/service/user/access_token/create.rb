# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::User::AccessToken::Create < Service::Base
  attr_reader :user, :name, :permission, :expires_at

  def initialize(user, name:, permission:, expires_at: nil)
    super()

    @user       = user
    @name       = name
    @permission = permission
    @expires_at = expires_at
  end

  def execute
    Token
      .where(
        action:     'api',
        persistent: true,
      )
      .create!(
        name:        name,
        user:        user,
        expires_at:  expires_at_as_time,
        preferences: {
          permission: permission
        }
      )
  end

  private

  def expires_at_as_time
    return if expires_at.blank?

    date = Date.parse(expires_at.to_s)

    Time.use_zone(Setting.get('timezone_default')) { date.beginning_of_day }
  end
end
