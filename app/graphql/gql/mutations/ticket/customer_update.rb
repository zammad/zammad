# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::CustomerUpdate < BaseMutation
    description 'Update a ticket.'

    argument :ticket_id, GraphQL::Types::ID, loads: Gql::Types::TicketType, description: 'The ticket to be updated'
    argument :input, Gql::Types::Input::Ticket::CustomerUpdateInputType, description: 'The ticket update data'

    field :ticket, Gql::Types::TicketType, description: 'The updated ticket.'

    def self.authorize(_obj, ctx)
      ctx[:current_user].permissions?(['ticket.agent'])
    end

    def resolve(ticket:, input:)
      { ticket: Service::Ticket::CustomerUpdate.new(current_user: context.current_user).execute(ticket: ticket, customer: input.customer, organization: input.organization) }
    end
  end
end
