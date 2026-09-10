# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class Ticket::Article::TranslationUpdates < BaseSubscription

    description 'Updates to triggered translations of the articles of a ticket'

    # Keyed by the ticket, not by the article: a ticket view would otherwise hold one subscription
    #   per article, and translating a whole ticket would need one per translated article.
    #   Ticket::ArticleUpdates addresses its article events the same way.
    #   Agent read access, as in Ticket::AIAssistance::SummaryUpdates: translating is an agent
    #   action, and the analytics run an event can carry is refused to everyone else.
    argument :ticket_id, GraphQL::Types::ID, description: 'The ticket whose article translations are subscribed to', loads: Gql::Types::TicketType, loads_pundit_method: :agent_read_access?
    argument :target_locale, String, description: 'The locale to translate into, e.g. "de-de".'

    field :article, Gql::Types::Ticket::ArticleType, null: true, description: 'The article the translation belongs to'
    field :translation, Gql::Types::ContentTranslationType, null: true, description: 'The translation'
    field :error, Gql::Types::AsyncExecutionErrorType, null: true, description: 'Error that occurred during the execution of the async job'
    field :analytics, Gql::Types::AI::Analytics::MetadataType, null: true, description: 'Analytics metadata'

    # Callers hand over the translated object and the locale; how this subscription is addressed is
    #   its own business, as in Ticket::ArticleUpdates.
    def self.trigger_for(article, target_locale, payload)
      trigger(
        payload.merge(article:),
        arguments: { ticket_id: Gql::ZammadSchema.id_from_object(article.ticket), target_locale: }
      )
    end

    def update(ticket:, target_locale:)
      article = object[:article]

      # Every subscriber of the ticket receives the event, so the article decides who sees it - it
      #   may have been merged into a ticket the subscriber has no access to since the trigger.
      return no_update if !pundit_authorized?(article, :agent_read_access?)
      return { article:, error: object[:error] } if object[:error]

      if (ai_analytics_run = ::AI::Analytics::Run.find_by(id: object[:ai_analytics_run_id]))
        analytics = {
          run:   ai_analytics_run,
          usage: ai_analytics_run.usage_by(context.current_user),
        }
      end

      {
        article:,
        translation: object[:translation],
        analytics:,
      }
    end
  end
end
