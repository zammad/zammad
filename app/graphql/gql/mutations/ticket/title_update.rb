# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::TitleUpdate < BaseMutation
    description 'Update a ticket title.'

    argument :ticket_id, GraphQL::Types::ID, loads: Gql::Types::TicketType, loads_pundit_method: :update?, description: 'The ticket to be updated'
    argument :title, String, description: 'The title of the ticket.', required: true

    field :ticket, Gql::Types::TicketType, description: 'The updated ticket.'

    def resolve(ticket:, title:)
      Service::Ticket::ForcedUpdate
        .new(ticket, { title: })
        .execute

      { ticket: }
    end
  end
end
