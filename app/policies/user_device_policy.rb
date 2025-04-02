# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class UserDevicePolicy < ApplicationPolicy
  def log?
    user&.permissions?('user_preferences.device')
  end
end
