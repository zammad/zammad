# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::CustomerUpdate < BaseMutation
    description 'Update a ticket.'

    argument :ticket_id, GraphQL::Types::ID, loads: Gql::Types::TicketType, loads_pundit_method: :agent_update_access?, description: 'The ticket to be updated'
    argument :input, Gql::Types::Input::Ticket::CustomerUpdateInputType, description: 'The ticket update data'

    field :ticket, Gql::Types::TicketType, description: 'The updated ticket.'

    def resolve(ticket:, input:)
      Service::Ticket::ForcedUpdate
        .new(ticket, input.to_h)
        .execute

      { ticket: }
    end
  end
end
