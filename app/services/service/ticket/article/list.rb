# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::Article::List < Service::BaseWithCurrentUser
  def execute(ticket:)
    if TicketPolicy.new(current_user, ticket).agent_read_access?
      ::Ticket::Article.where(ticket:).reorder(:id)
    else
      ::Ticket::Article.where(ticket:, internal: false).reorder(:id)
    end
  end
end
