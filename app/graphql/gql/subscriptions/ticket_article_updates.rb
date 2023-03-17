# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class TicketArticleUpdates < BaseSubscription

    argument :ticket_id, GraphQL::Types::ID, description: 'Ticket identifier'

    description 'Updates to ticket records'

    field :created_article, Gql::Types::Ticket::ArticleType, description: 'New ticket article'
    field :updated_article, Gql::Types::Ticket::ArticleType, description: 'Changed ticket article'
    field :deleted_article_id, GraphQL::Types::ID, description: 'ID of removed ticket article'

    class << self
      # Helper methods for triggering with custom payload.
      def trigger_after_create(article)
        trigger({ created_article: article }, arguments: { ticket_id: Gql::ZammadSchema.id_from_object(article.ticket) })
      end

      def trigger_after_update(article)
        trigger({ updated_article: article }, arguments: { ticket_id: Gql::ZammadSchema.id_from_object(article.ticket) })
      end

      def trigger_after_destroy(article)
        trigger({ deleted_article_id: Gql::ZammadSchema.id_from_object(article) }, arguments: { ticket_id: Gql::ZammadSchema.id_from_object(article.ticket) })
      end
    end

    def authorized?(ticket_id:)
      Gql::ZammadSchema.authorized_object_from_id ticket_id, type: ::Ticket, user: context.current_user
    end

    # This needs to be passed a hash with the correct field name containing the article payload as root object,
    #   as we cannot change the (graphql-ruby) function signature of update(ticket_id:).
    def update(ticket_id:)
      object
    end
  end
end
