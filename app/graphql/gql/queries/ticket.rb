# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Ticket < BaseQuery

    description 'Fetch a ticket by ID'

    argument :ticket_id, ID, loads: Gql::Types::TicketType, description: 'Ticket ID'

    type Gql::Types::TicketType, null: false

    def resolve(ticket:)
      ticket
    end
  end
end
