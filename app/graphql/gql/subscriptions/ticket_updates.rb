# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class TicketUpdates < BaseSubscription

    argument :ticket_id, GraphQL::Types::ID, required: true, description: 'Ticket identifier'

    description 'Updates to ticket records'

    field :ticket, Gql::Types::TicketType, null: true, description: 'Updated ticket'

    def authorized?(ticket_id:)
      Gql::ZammadSchema.authorized_object_from_id ticket_id, type: ::Ticket, user: context.current_user
    end

    def update(ticket_id:)
      { ticket: object }
    end
  end
end
