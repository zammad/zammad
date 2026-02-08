# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Ticket::History < BaseQuery
    description 'Fetch history of a ticket'

    argument :ticket_id, ID, loads: Gql::Types::TicketType, description: 'Ticket ID'

    type [Gql::Types::HistoryGroupType], null: false

    requires_permission 'ticket.agent'

    def resolve(ticket:)
      Service::History::Group
        .new(current_user: context.current_user)
        .execute(object: ticket)
    end
  end
end
