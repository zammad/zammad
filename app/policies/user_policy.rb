# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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
    return true if user.permissions?('admin.user')
    # forbid non-agents to change users
    return false if !user.permissions?('ticket.agent')

    # allow agents to change customers
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

    record.organization_id == user.organization_id
  end

  class Scope < ApplicationPolicy::Scope

    def resolve
      if user.permissions?(['ticket.agent', 'admin.user'])
        scope.all
      else
        scope.where(id: user.id)
      end
    end
  end
end
