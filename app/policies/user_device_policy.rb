# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class UserDevicePolicy < ApplicationPolicy
  def log?
    user&.permissions?('user_preferences.device')
  end
end
