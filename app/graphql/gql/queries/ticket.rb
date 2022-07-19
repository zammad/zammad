# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Ticket < BaseQuery

    description 'Fetch a ticket by ID'

    # Pundit authorization will be done via TicketType.
    argument :ticket_id, GraphQL::Types::ID, required: false, description: 'Ticket ID'
    argument :ticket_internal_id, Integer, required: false, description: 'Ticket internalId'
    argument :ticket_number, String, required: false, description: 'Ticket number'

    type Gql::Types::TicketType, null: false

    def resolve(ticket_id: nil, ticket_internal_id: nil, ticket_number: nil)
      if ticket_id
        return Gql::ZammadSchema.verified_object_from_id(ticket_id, type: ::Ticket)
      end
      if ticket_internal_id
        return ::Ticket.find_by(id: ticket_internal_id) || raise(ActiveRecord::RecordNotFound, "The ticket #{ticket_internal_id} could not be found.")
      end
      if ticket_number
        return ::Ticket.find_by(number: ticket_number) || raise(ActiveRecord::RecordNotFound, "The ticket ##{ticket_number} could not be found.")
      end

      raise __("One of the arguments 'ticket_id', 'ticket_internal_id' or 'ticket_number' must be provided.")
    end
  end
end
