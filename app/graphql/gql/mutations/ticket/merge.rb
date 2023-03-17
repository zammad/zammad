# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::Merge < BaseMutation
    description 'Create a new ticket.'

    argument :source_ticket_id, GraphQL::Types::ID, loads: Gql::Types::TicketType, description: 'The (source) ticket that should be merged into another one'
    argument :target_ticket_id, GraphQL::Types::ID, loads: Gql::Types::TicketType, description: 'The (target) ticket that another ticket should be merged into'

    field :source_ticket, Gql::Types::TicketType, description: 'The source ticket after merging.'
    field :target_ticket, Gql::Types::TicketType, description: 'The target ticket after merging.'

    def self.authorize(_obj, ctx)
      ctx[:current_user].permissions?(['ticket.agent'])
    end

    def resolve(source_ticket:, target_ticket:)
      Service::Ticket::Merge.new(current_user: context.current_user).execute(source_ticket: source_ticket, target_ticket: target_ticket)
      { source_ticket: source_ticket, target_ticket: target_ticket }
    rescue Exceptions::UnprocessableEntity => e
      error_response({ message: e.message })
    end
  end
end
