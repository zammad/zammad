# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class UserDevicePolicy < ApplicationPolicy
  def log?
    user&.permissions?('user_preferences.device')
  end

  def destroy?
    owner?
  end

  private

  def owner?
    user == record.user
  end
end
