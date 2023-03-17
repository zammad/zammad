# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class TicketUpdates < BaseSubscription
    description 'Updates to ticket records'

    argument :ticket_id, GraphQL::Types::ID, description: 'Ticket identifier'

    field :ticket, Gql::Types::TicketType, description: 'Updated ticket'

    def authorized?(ticket_id:)
      Gql::ZammadSchema.authorized_object_from_id ticket_id, type: ::Ticket, user: context.current_user
    end

    def update(ticket_id:)
      { ticket: object }
    end
  end
end
