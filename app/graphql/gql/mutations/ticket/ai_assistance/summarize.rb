# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::AIAssistance::Summarize < BaseMutation
    description 'Return current summary or trigger generation in the background'

    argument :ticket_id, GraphQL::Types::ID, loads: Gql::Types::TicketType, loads_pundit_method: :agent_read_access?, description: 'The ticket to fetch the summary for'
    argument :regeneration_of_id, GraphQL::Types::ID, loads: Gql::Types::AI::Analytics::RunType, required: false, description: 'The previous AI run to regenerate the summary for (if any)'

    field :summary, Gql::Types::Ticket::AIAssistance::SummaryType, description: 'Different parts of the generated summary'
    field :analytics, Gql::Types::AI::Analytics::MetadataType, description: 'Analytics metadata', null: true

    def resolve(ticket:, regeneration_of: nil)
      Service::CheckFeatureEnabled.execute(name: 'ai_assistance_ticket_summary')
      Service::CheckFeatureEnabled.execute(name: 'ai_provider', custom_error_message: __('AI provider is not configured.'))

      if regeneration_of
        return enqueue_job(ticket, regeneration_of:)
      end

      ai_result = Service::Ticket::AIAssistance::Summarize
        .with_current_user(context.current_user)
        .execute(
          locale:               context.current_user.locale,
          ticket:,
          persistence_strategy: :stored_only,
        )

      if ai_result&.content.blank?
        return enqueue_job(ticket)
      end

      return_stored_result(ticket, ai_result)
    end

    private

    def enqueue_job(ticket, regeneration_of: nil)
      # Trigger background job to generate the summary.
      TicketAIAssistanceSummarizeJob.perform_later(ticket, context.current_user.locale, regeneration_of:)

      {
        summary: nil,
        reason:  nil,
      }
    end

    def return_stored_result(ticket, ai_result)
      usage = ai_result.ai_analytics_run&.usage_by(context.current_user)
      is_unread = ticket.ai_summary_unread?(context.current_user, ai_result.ai_analytics_run)

      {
        summary:   ai_result.content,
        analytics: {
          run:       ai_result.ai_analytics_run,
          usage:,
          is_unread:
        }
      }
    end
  end
end
