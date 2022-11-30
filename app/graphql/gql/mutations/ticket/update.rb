# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::Update < BaseMutation
    description 'Update a ticket.'

    argument :ticket, Gql::Types::Input::Locator::TicketInputType, description: 'Ticket locator'
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
