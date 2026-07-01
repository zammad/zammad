# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Ticket::AI::RelatedKnowledgeBaseAnswers < BaseQuery
    description 'Find knowledge base answers related to a ticket via vector similarity search'

    argument :ticket_id, GraphQL::Types::ID, loads: Gql::Types::TicketType, loads_pundit_method: :agent_read_access?, description: 'The ticket to find related knowledge base answers for'

    type Gql::Types::Ticket::AI::RelatedKnowledgeBaseAnswersResultType, null: false

    requires_permission 'knowledge_base.*'
    requires_enabled_setting 'ai_provider'

    def resolve(ticket:)
      raise Exceptions::UnprocessableContent, __('Knowledge base vector search is not available.') if !Service::AI::VectorDB::Available.execute

      Service::Ticket::AI::RelatedKnowledgeBaseAnswers
        .with_current_user(context.current_user)
        .execute(ticket:)
    end
  end
end
