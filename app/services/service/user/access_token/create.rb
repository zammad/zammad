# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

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
        expires_at:  expires_at,
        preferences: {
          permission: permission
        }
      )
  end
end
