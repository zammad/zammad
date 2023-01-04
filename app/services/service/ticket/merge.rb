# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::Merge < Service::BaseWithCurrentUser

  def execute(source_ticket:, target_ticket:)
    Pundit.authorize(current_user, source_ticket, :agent_update_access?)
    Pundit.authorize(current_user, target_ticket, :agent_update_access?)

    source_ticket.merge_to(
      ticket_id:     target_ticket.id,
      created_by_id: current_user.id,
    )
  end
end
