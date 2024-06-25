# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::Update < BaseMutation
    include Gql::Mutations::Ticket::Concerns::HandlesGroup

    description 'Update a ticket.'

    argument :ticket_id, GraphQL::Types::ID, loads: Gql::Types::TicketType, description: 'The ticket to be updated'
    argument :input, Gql::Types::Input::Ticket::UpdateInputType, description: 'The ticket data'

    field :ticket, Gql::Types::TicketType, description: 'The updated ticket. If this is present but empty, the mutation was successful but the user has no rights to view the updated ticket.'

    def self.authorize(_obj, ctx)
      ctx.current_user.permissions?(['ticket.agent', 'ticket.customer'])
    end

    def resolve(ticket:, input:)
      return group_has_no_email_error if !group_has_email?(input: input)

      {
        ticket: Service::Ticket::Update
          .new(current_user: context.current_user)
          .execute(ticket: ticket, ticket_data: input)
      }
    end
  end
end
