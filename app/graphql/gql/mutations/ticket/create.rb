# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::Create < BaseMutation
    description 'Create a new ticket.'

    argument :input, Gql::Types::Input::Ticket::CreateInputType, description: 'The ticket data'

    field :ticket, Gql::Types::TicketType, description: 'The created ticket.'

    def self.authorize(_obj, ctx)
      ctx[:current_user].permissions?(['ticket.agent', 'ticket.customer'])
    end

    def resolve(input:)
      { ticket: Service::Ticket::Create.new(current_user: context.current_user).execute(ticket_data: input.to_h) }
    end
  end
end
