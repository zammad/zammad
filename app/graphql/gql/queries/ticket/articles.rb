# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Ticket::Articles < BaseQuery

    description 'Fetch a ticket by ID'

    # Pundit authorization will be done via TicketType.
    argument :ticket_id, GraphQL::Types::ID, required: true, description: 'Ticket ID'

    type Gql::Types::Ticket::ArticleType.connection_type, null: false

    def resolve(ticket_id:)
      ticket = Gql::ZammadSchema.authorized_object_from_id(ticket_id, type: ::Ticket, user: context.current_user)
      ::Ticket::Article.where(ticket: ticket).order(:id)
    end
  end
end
