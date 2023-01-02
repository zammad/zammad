# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class TicketUpdates < BaseSubscription

    argument :ticket_id, GraphQL::Types::ID, description: 'Ticket identifier'

    description 'Updates to ticket records'

    field :ticket, Gql::Types::TicketType, description: 'Updated ticket'
    field :ticket_article, Gql::Types::Ticket::ArticleType, description: 'Updated ticket article (optional)'

    def authorized?(ticket_id:)
      Gql::ZammadSchema.authorized_object_from_id ticket_id, type: ::Ticket, user: context.current_user
    end

    # This can either be passed a ::Ticket for ticket updates, or a ::Ticket::Article if a specific article was changed.
    def update(ticket_id:)
      if object.is_a?(::Ticket::Article)
        return { ticket: object.ticket, ticket_article: object }
      end

      { ticket: object }
    end
  end
end
