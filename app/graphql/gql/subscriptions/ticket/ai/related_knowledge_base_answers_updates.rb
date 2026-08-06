# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  # Content-free ping: signals that the related knowledge base answers for a ticket may now be
  # available (e.g. the summary the search relies on finished generating). Clients react by
  # (re)running the synchronous ticketAIRelatedKnowledgeBaseAnswers query.
  class Ticket::AI::RelatedKnowledgeBaseAnswersUpdates < BaseSubscription
    description 'Ping that the related knowledge base answers for a ticket may have changed'

    argument :ticket_id, GraphQL::Types::ID, loads: Gql::Types::TicketType, loads_pundit_method: :agent_read_access?, description: 'Ticket identifier'

    field :ticket_id, GraphQL::Types::ID, null: true, description: 'Identifier of the ticket whose related knowledge base answers may have changed (null on subscribe)'
    field :error, String, null: true, description: 'Set when the embedding could not be produced; the client shows the error state instead of re-running the search'

    # Mirrors the query: agents without knowledge base permission also get suggestions (published
    # answers only), so they need the ping as well.
    requires_permission 'ticket.agent'
    requires_enabled_setting 'ai_provider'

    def update(ticket:)
      { ticket_id: Gql::ZammadSchema.id_from_object(ticket), error: object&.dig(:error) }
    end
  end
end
