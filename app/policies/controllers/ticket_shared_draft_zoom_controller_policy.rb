# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Controllers::TicketSharedDraftZoomControllerPolicy < Controllers::ApplicationControllerPolicy
  def show?
    access?(__method__)
  end

  def create?
    access?(__method__)
  end

  def update?
    access?(__method__)
  end

  def destroy?
    access?(__method__)
  end

  def import_attachments?
    access?(__method__)
  end

  private

  def access?(_method)
    ticket_id = record.params[:ticket_id]
    ticket    = Ticket.find ticket_id

    TicketPolicy.new(user, ticket).agent_update_access?
  end
end
