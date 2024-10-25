# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class ChecklistPolicy < ApplicationPolicy
  def show?
    check_prerequisites? && ticket_policy.agent_read_access?
  end

  def update?
    check_prerequisites? && ticket_policy.agent_update_access?
  end

  def destroy?
    check_prerequisites? && ticket_policy.agent_update_access?
  end

  private

  def check_prerequisites?
    Setting.get('checklist') && record&.ticket
  end

  def ticket_policy
    TicketPolicy.new(user, record.ticket)
  end
end
