# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::Update < BaseMutation
    description 'Update a ticket.'

    argument :ticket_id, GraphQL::Types::ID, loads: Gql::Types::TicketType, description: 'The ticket to be updated'
    argument :input, Gql::Types::Input::Ticket::UpdateInputType, description: 'The ticket data'

    field :ticket, Gql::Types::TicketType, description: 'The updated ticket.'

    def self.authorize(_obj, ctx)
      ctx[:current_user].permissions?(['ticket.agent', 'ticket.customer'])
    end

    def resolve(ticket:, input:)
      { ticket: Service::Ticket::Update.new(current_user: context.current_user).execute(ticket: ticket, ticket_data: input.to_h) }
    end
  end
end
