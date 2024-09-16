# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class MacroPolicy < ApplicationPolicy
  def show?
    return true if admin?

    agent_accessible?
  end

  def create?
    admin?
  end

  def update?
    admin?
  end

  def destroy?
    admin?
  end

  private

  def admin?
    user.permissions?('admin.group')
  end

  def agent_accessible?
    return false if !user.permissions?('ticket.agent')
    return false if !record.active

    group_ids = record.groups.pluck(:id)

    return true if group_ids.blank?

    group_ids.intersect? user.group_ids
  end
end
