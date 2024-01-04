# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class VersionPolicy < ApplicationPolicy
  def show?
    user.permissions?('admin')
  end
end
