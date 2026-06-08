# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::Article::List < Service::Base
  requires_current_user!

  attr_reader :ticket

  def initialize(ticket:)
    @ticket = ticket
  end

  def execute
    if TicketPolicy.new(current_user, ticket).agent_read_access?
      ::Ticket::Article.where(ticket: ticket).reorder(:id)
    else
      ::Ticket::Article.where(ticket: ticket, internal: false).reorder(:id)
    end
  end
end
