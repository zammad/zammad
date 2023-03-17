# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class TemplatePolicy < ApplicationPolicy
  def show?
    return true if admin?
    return true if user.permissions?('ticket.agent') && record.active

    false
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
    user.permissions?('admin.template')
  end
end
