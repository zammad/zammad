# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class RolePolicy < ApplicationPolicy
  def show?
    return true if admin?

    user.role_ids.include? record.id
  end

  private

  def admin?
    user.permissions?('admin.role')
  end
end
