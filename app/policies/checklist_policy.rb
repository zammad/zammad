# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class ChecklistPolicy < ApplicationPolicy
  def show?
    ticket_policy.agent_read_access?
  end

  def create?
    ticket_policy.agent_update_access?
  end

  def update?
    ticket_policy.agent_update_access?
  end

  def destroy?
    ticket_policy.agent_update_access?
  end

  private

  def ticket_policy
    TicketPolicy.new(user, record.ticket)
  end
end
