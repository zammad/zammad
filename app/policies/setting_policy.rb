# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class SettingPolicy < ApplicationPolicy

  def show?
    permitted?
  end

  def update?
    permitted?
  end

  private

  def permitted?
    return true if !record.preferences[:permission]

    user.permissions?(record.preferences[:permission])
  end
end
