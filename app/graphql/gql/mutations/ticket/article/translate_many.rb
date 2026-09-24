# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::Article::TranslateMany < BaseMutation
    description 'Check or generate translations for several articles of a ticket'

    extras [:lookahead]

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
    argument :generate_missing, Boolean, required: false, default_value: false, description: 'Generate missing translations instead of only checking availability'
    # rubocop:enable GraphQL/ExtractInputType

    field :results, [Gql::Types::Ticket::Article::TranslationResultType], null: false, description: 'Translation availability and outcomes for all selected articles'

    field :pending_article_ids, [GraphQL::Types::ID], null: false, description: 'Articles whose translations will arrive through the subscription'

    def resolve(ticket:, target_locale:, generate_missing:, lookahead:, first_articles_count:, load_first_articles:, page_size: nil, before_cursor: nil, after_cursor: nil)
      scope = Service::Ticket::Article::List.with_current_user(context.current_user).execute(ticket:)
      articles = load_first_articles ? page(scope, first: first_articles_count) : []
      articles |= page(scope, last: page_size, before: before_cursor, after: after_cursor)

      translations = Service::ContentTranslation::TicketArticle::TranslateMany
        .with_current_user(context.current_user)
        .execute(articles:, target_locale:, generate_missing:)

      context.scoped_set!(:article_translations, resolved_translations(translations, target_locale))
      if lookahead.selection(:results).selection(:article).selects?(:translation)
        context.scoped_set!(:article_translation_content_locale, target_locale)
      end

      {
        results:             translations.map { |entry| result(entry) },
        pending_article_ids: translations.filter_map do |entry|
          Gql::ZammadSchema.id_from_object(entry[:article]) if entry.key?(:translation) && entry[:translation].nil?
        end,
      }
    end

    private

    def result(entry)
      translation = entry[:translation]

      {
        article:    entry[:article],
        translated: translation&.translated,
        analytics:  translation && {
          run:   translation.analytics_run,
          usage: translation.analytics_run&.usage_by(context.current_user),
        },
      }
    end

    # Batch loaders are cleared after the mutation root; scoped data survives into its fields.
    def resolved_translations(translations, target_locale)
      translations.filter_map do |entry|
        next if !entry.key?(:translation) || entry[:translation]&.translated == false

        [[entry[:article].id, target_locale], Service::ContentTranslation::TicketArticle.for_display(entry[:article], entry[:translation])]
      end.to_h
    end

    def page(scope, **arguments)
      context.schema.connections.wrapper_for(scope).new(scope, context:, **arguments).nodes.to_a
    end
  end
end
