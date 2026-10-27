# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class SettingPolicy < ApplicationPolicy

  def show?
    permitted?
  end

  def update?
    permitted?
  end

  private

  def permitted?
    return false if record.protected?

    user.permissions?(record.required_permission)
  end
end
