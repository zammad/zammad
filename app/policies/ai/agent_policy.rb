# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class AI::AgentPolicy < ApplicationPolicy
  def show?
    return true if user.permissions?(['admin.ai_agent', 'admin.trigger', 'admin.scheduler'])

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
    user.permissions?('admin.ai_agent')
  end

  def agent_accessible?
    return false if !user.permissions?('ticket.agent')
    return false if !record.active

    true
  end
end
