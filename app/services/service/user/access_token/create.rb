# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::User::AccessToken::Create < Service::Base
  requires_current_user!

  attr_reader :name, :permission, :expires_at

  def initialize(name:, permission:, expires_at: nil)
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
        user:        current_user,
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
