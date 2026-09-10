# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::Article::Translate < BaseMutation
    description 'Return a stored translation of an article or trigger its generation in the background'

    # Translating is an agent action, as is the analytics run it produces - anyone refused that run
    #   by AI::Analytics::RunPolicy would get an error instead of a translation. Hence agent read
    #   access rather than :show?, which grants a user holding both ticket.agent and ticket.customer
    #   access to a ticket they are the customer of, outside of their groups.
    requires_permission 'ticket.agent'

    argument :article_id, GraphQL::Types::ID, loads: Gql::Types::Ticket::ArticleType, loads_pundit_method: :agent_read_access?, description: 'The article to translate'
    argument :target_locale, String, description: 'The locale to translate into, e.g. "de-de".'
    argument :force, Boolean, required: false, default_value: false, description: 'Translate even when the article is already in the target locale.'

    field :translation, Gql::Types::ContentTranslationType, null: true, description: 'The translation, if one is available already'
    field :analytics, Gql::Types::AI::Analytics::MetadataType, null: true, description: 'Analytics metadata'

    def resolve(article:, target_locale:, force:)
      # No feature check here on purpose: which service translates, and what it needs to be
      #   configured, is the translation service's business, not this mutation's.
      translation = translate(article, target_locale, force:)

      # nil means the translation service deferred it; the subscription delivers the outcome.
      return pending if translation.nil?

      {
        translation:,
        analytics:   {
          run:   translation.analytics_run,
          usage: translation.analytics_run&.usage_by(context.current_user),
        },
      }
    end

    private

    # The source language is deliberately no argument: the article carries it, so a client cannot
    #   know it better. Whether the answer comes from this request or through the subscription is the
    #   translation service's decision, so nothing about it is passed here either.
    def translate(article, target_locale, force:)
      Service::ContentTranslation::TicketArticle
        .execute(object: article, target_locale:, force:)
    end

    def pending
      {
        translation: nil,
        analytics:   nil,
      }
    end
  end
end
