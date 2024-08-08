# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Controllers::TicketChecklistItemsControllerPolicy < Controllers::ApplicationControllerPolicy
  def create?
    update_access_via_ticket?
  end

  def destroy?
    update_access_via_ticket?
  end

  def update?
    update_access_via_ticket?
  end

  private

  def ticket_policy
    @ticket_policy ||= TicketPolicy.new(user, Ticket.lookup(id: record.params[:ticket_id]))
  end

  def update_access_via_ticket?
    ticket_policy.agent_update_access?
  end
end
