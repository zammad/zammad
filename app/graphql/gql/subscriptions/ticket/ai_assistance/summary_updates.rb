# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class Ticket::AIAssistance::SummaryUpdates < BaseSubscription

    description 'Updates to triggered AI assistance summary'

    argument :ticket_id, GraphQL::Types::ID, loads: Gql::Types::TicketType, loads_pundit_method: :agent_read_access?, description: 'Ticket identifier'
    argument :locale, String, 'The locale to use, e.g. "de-de".'

    field :summary, Gql::Types::Ticket::AIAssistance::SummaryType, description: 'Different parts of the generated summary'
    field :error, Gql::Types::AsyncExecutionErrorType, description: 'Error that occurred during the execution of the async job'
    field :analytics, Gql::Types::AI::Analytics::MetadataType, description: 'Analytics metadata', null: true

    requires_enabled_setting 'ai_provider'
    requires_enabled_setting 'ai_assistance_ticket_summary'

    def update(ticket:, locale:)
      return { error: object[:error] } if object[:error]

      if (ai_analytics_run = ::AI::Analytics::Run.find_by(id: object[:ai_analytics_run_id]))
        usage     = ai_analytics_run&.usage_by(context.current_user)
        is_unread = ticket.ai_summary_unread?(context.current_user, ai_analytics_run)

        analytics = {
          run:       ai_analytics_run,
          usage:,
          is_unread:
        }
      end

      {
        summary:   object[:summary],
        analytics:,
      }
    end
  end
end
