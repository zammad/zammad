# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::Article::TranslateMany < BaseMutation
    description 'Translate several articles of a ticket at once, for an agent who switched the whole ticket to a target language'

    # Agent read access on the ticket, as in Ticket::Article::Translate; who may translate a whole
    #   ticket on top of that is the service's answer.
    requires_permission 'ticket.agent'

    argument :ticket_id, GraphQL::Types::ID, loads: Gql::Types::TicketType, loads_pundit_method: :agent_read_access?, description: 'The ticket whose articles are translated'
    # rubocop:disable GraphQL/ExtractInputType -- Keep the article query pagination interface.
    argument :first_articles_count, Integer, required: false, default_value: 1, description: 'Number of leading articles, as in the article list'
    argument :load_first_articles, Boolean, required: false, default_value: true, description: 'Include the leading articles'
    argument :page_size, Integer, required: false, description: 'Number of trailing articles'
    argument :before_cursor, String, required: false, description: 'Fetch articles before this cursor'
    argument :after_cursor, String, required: false, description: 'Fetch articles after this cursor'
    argument :target_locale, String, description: 'The locale to translate into, e.g. "de-de".'
    # rubocop:enable GraphQL/ExtractInputType

    field :translations, [Gql::Types::Ticket::Article::TranslationType], null: true, description: 'The translations that are available already; the others are delivered by the subscription'

    field :pending_article_ids, [GraphQL::Types::ID], null: false, description: 'Articles whose translations will arrive through the subscription'

    def resolve(ticket:, target_locale:, first_articles_count:, load_first_articles:, page_size: nil, before_cursor: nil, after_cursor: nil)
      scope = Service::Ticket::Article::List.with_current_user(context.current_user).execute(ticket:)
      articles = load_first_articles ? page(scope, first: first_articles_count) : []
      articles |= page(scope, last: page_size, before: before_cursor, after: after_cursor)

      translations = Service::ContentTranslation::TicketArticle::TranslateMany
        .with_current_user(context.current_user)
        .execute(articles:, target_locale:)

      ready, pending = translations.partition { |entry| entry[:translation] }

      {
        translations:        ready.map { |entry| for_display(entry) },
        pending_article_ids: pending.map { |entry| Gql::ZammadSchema.id_from_object(entry[:article]) },
      }
    end

    private

    def page(scope, **arguments)
      context.schema.connections.wrapper_for(scope).new(scope, context:, **arguments).nodes.to_a
    end

    def for_display(entry)
      {
        article:     entry[:article],
        translation: Service::ContentTranslation::TicketArticle.for_display(entry[:article], entry[:translation]),
      }
    end
  end
end
