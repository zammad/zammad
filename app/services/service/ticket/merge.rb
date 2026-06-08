# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::Merge < Service::Base
  requires_current_user!

  attr_reader :source_ticket, :target_ticket

  def initialize(source_ticket:, target_ticket:)
    @source_ticket = source_ticket
    @target_ticket = target_ticket
  end

  def execute
    Pundit.authorize(current_user, source_ticket, :agent_update_access?)
    Pundit.authorize(current_user, target_ticket, :agent_update_access?)

    source_ticket.merge_to(
      ticket_id:     target_ticket.id,
      created_by_id: current_user.id,
    )
  end
end
