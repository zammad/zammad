# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class SessionsPolicy < ApplicationPolicy
  def impersonate?
    user.permissions?('admin.user')
  end
end
