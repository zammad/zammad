# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class VersionPolicy < ApplicationPolicy
  def show?
    user.permissions?('admin.version')
  end
end
