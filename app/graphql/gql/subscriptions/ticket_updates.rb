# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class TicketUpdates < BaseSubscription
    description 'Updates to ticket records'

    argument :ticket_id, GraphQL::Types::ID, description: 'Ticket identifier'
    argument :initial, Boolean, default_value: false, description: 'Return initial ticket data by subscribing'

    field :ticket, Gql::Types::TicketType, description: 'Updated ticket'

    # This is needed to ensure that the subscription is unique for each ticket and that `initial` is not considered.
    def self.topic_for(arguments:, field:, scope:)
      super(arguments: { 'ticketId' => arguments['ticketId'] }, field:, scope:)
    end

    def authorized?(ticket_id:, initial:)
      Gql::ZammadSchema.authorized_object_from_id ticket_id, type: ::Ticket, user: context.current_user
    end

    def subscribe(ticket_id:, initial:)
      return {} if !initial

      { ticket: Gql::ZammadSchema.object_from_id(ticket_id, type: ::Ticket) }
    end

    def update(ticket_id:, initial:)
      { ticket: object }
    end
  end
end
