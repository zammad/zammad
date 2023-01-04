# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::CustomerUpdate < Service::BaseWithCurrentUser

  def execute(ticket:, customer:, organization: nil)

    Pundit.authorize current_user, ticket, :agent_update_access?

    ticket.with_lock do
      ticket.customer = customer
      ticket.organization = organization if organization
      ticket.save!
    end

    ticket
  end
end
