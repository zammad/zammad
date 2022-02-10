# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class TicketById < BaseQuery

    description 'Fetch a ticket by ID'

    def self.authorize(_obj, ctx)
      # Pundit authorization will be done via TicketType.
      ctx.current_user
    end

    argument :ticket_id, GraphQL::Types::ID, required: true, description: 'Ticket ID'

    type Gql::Types::TicketType, null: false

    def resolve(ticket_id: nil)
      Gql::ZammadSchema.object_from_id(ticket_id, context) || raise("Cannot find ticket #{ticket_id}")
    end
  end
end
