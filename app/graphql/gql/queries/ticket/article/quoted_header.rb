# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Ticket::Article::QuotedHeader < BaseQuery

    description 'Header lines of an article to quote when forwarding or replying to it'

    argument :article_id, GraphQL::Types::ID, loads: Gql::Types::Ticket::ArticleType, description: 'The article to be forwarded or replied to'

    type Gql::Types::Ticket::Article::QuotedHeaderType, null: false

    requires_permission 'ticket.agent'
    requires_enabled_setting 'ui_ticket_zoom_article_email_full_quote_header'

    def resolve(article:)
      Service::Ticket::Article::QuotedHeader
        .with_current_user(context.current_user)
        .execute(article:)
    end
  end
end
