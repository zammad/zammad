# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AI::Analytics::RunPolicy < ApplicationPolicy
  def show?
    case record.related_object
    when Ticket
      TicketPolicy.new(user, record.related_object).agent_read_access?
    when Ticket::Article
      # Resolved rather than stored, so a merged article is authorized through the ticket it
      #   belongs to now.
      TicketPolicy.new(user, record.related_object.ticket).agent_read_access?
    else
      user.permissions?('ticket.agent')
    end
  end
end
