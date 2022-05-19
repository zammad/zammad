# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class UserPolicy < ApplicationPolicy

  def show?
    return true if user.permissions?('admin.*')
    return true if own_account?
    return true if user.permissions?('ticket.agent')
    # check same organization for customers
    return false if !user.permissions?('ticket.customer')

    same_organization?
  end

  def update?
    # full access for admins
    return true if user.permissions?('admin.user')
    # forbid non-agents to change users
    return false if !user.permissions?('ticket.agent')

    # allow agents to change customers only
    return false if record.permissions?(['admin.user', 'ticket.agent'])

    record.permissions?('ticket.customer')
  end

  def destroy?
    user.permissions?('admin.user')
  end

  private

  def own_account?
    record.id == user.id
  end

  def same_organization?
    return false if record.organization_id.blank?
    return false if user.organization_id.blank?

    user.organization_id?(record.organization_id)
  end
end
