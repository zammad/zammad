# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class ChecklistTemplatePolicy < ApplicationPolicy
  def show?
    agent? || admin?
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

  def agent?
    user.permissions?('ticket.agent')
  end

  def admin?
    user.permissions?('admin.checklist')
  end
end
