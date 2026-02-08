# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class TicketUpdates < BaseSubscription
    description 'Updates to ticket records'

    include Gql::Subscriptions::Concerns::CanInitialResult

    unique_argument_id_key 'ticketId'

    argument :ticket_id, GraphQL::Types::ID, loads: Gql::Types::TicketType, description: 'Ticket identifier'

    field :ticket, Gql::Types::TicketType, description: 'Updated ticket'

    def subscribe(ticket:, initial:)
      return {} if !initial

      { ticket: }
    end

    def update(ticket:, initial:)
      { ticket: object }
    end
  end
end
