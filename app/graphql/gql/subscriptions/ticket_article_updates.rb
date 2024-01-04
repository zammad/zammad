# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class TicketArticleUpdates < BaseSubscription

    argument :ticket_id, GraphQL::Types::ID, description: 'Ticket identifier'

    description 'Changes to the list of ticket articles'

    field :add_article, Gql::Types::Ticket::ArticleType, description: 'A new article needs to be added to the list'
    field :update_article, Gql::Types::Ticket::ArticleType, description: 'An existing article was changed'
    field :remove_article_id, GraphQL::Types::ID, description: 'An article must be removed from the list'

    class << self
      # Helper methods for triggering with custom payload.
      def trigger_after_create(article)
        trigger_for_ticket(article, { article: article, event: :create })
      end

      def trigger_after_update(article)
        # Add information about changes to the internal flag for later processing.
        trigger_for_ticket(article, { article: article, event: :update, internal_changed?: article.previous_changes['internal'].present? })
      end

      def trigger_after_destroy(article)
        trigger_for_ticket(article, { article_id: Gql::ZammadSchema.id_from_object(article), event: :destroy })
      end

      def trigger_for_ticket(article, payload)
        trigger(payload, arguments: { ticket_id: Gql::ZammadSchema.id_from_object(article.ticket) })
      end
    end

    def authorized?(ticket_id:)
      Gql::ZammadSchema.authorized_object_from_id ticket_id, type: ::Ticket, user: context.current_user
    end

    # This needs to be passed a hash with the correct field name containing the article payload as root object,
    #   as we cannot change the (graphql-ruby) function signature of update(ticket_id:).
    def update(ticket_id:)
      event = object[:event]
      article = object[:article]

      # Always send remove events.
      if event == :destroy
        return { remove_article_id: object[:article_id] }
      end

      # Send create only for articles with permission.
      if event == :create
        return article_permission? ? { add_article: article } : no_update
      end

      # For updated articles, there is a special handling if visibility changed.
      if article_permission?
        # If permission to see the article was just added, treat it as an add event.
        return customer_visibility_changed? ? { add_article: article } : { update_article: article }

      elsif customer_visibility_changed?
        # If permission to see the article was just removed, treat it as a remove event.
        return { remove_article_id: Gql::ZammadSchema.id_from_object(article) }
      end

      no_update
    end

    private

    def customer_visibility_changed?
      object[:internal_changed?] && !TicketPolicy.new(context.current_user, object[:article].ticket).agent_read_access?
    end

    # Only send updates for articles with read permission.
    def article_permission?
      Pundit.authorize context.current_user, object[:article], :show?
    rescue Pundit::NotAuthorizedError
      false
    end
  end
end
