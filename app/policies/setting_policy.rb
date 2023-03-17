# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class SettingPolicy < ApplicationPolicy

  def show?
    permitted?
  end

  def update?
    permitted?
  end

  private

  def permitted?
    return false if record.preferences[:protected]
    return true if !record.preferences[:permission]

    user.permissions?(record.preferences[:permission])
  end
end
