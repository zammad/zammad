# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Ticket::AI::RelatedKnowledgeBaseAnswers < BaseQuery
    description 'Find knowledge base answers related to a ticket via vector similarity search'

    argument :ticket_id, GraphQL::Types::ID, loads: Gql::Types::TicketType, loads_pundit_method: :agent_read_access?, description: 'The ticket to find related knowledge base answers for'
    argument :include_drafts_and_archived, Boolean, required: false, default_value: false, description: 'Also search the drafts and archived answers the user may see, instead of only the internally visible ones'
    argument :include_linked_answers, Boolean, required: false, default_value: false, description: 'Also return answers already linked to the ticket, instead of leaving them out'

    type Gql::Types::Ticket::AI::RelatedKnowledgeBaseAnswersResultType, null: false

    # No knowledge base permission is required: which answers may be suggested is decided by the
    # search itself (KnowledgeBase::Answer.visible_to_user), so agents without knowledge base access
    # are suggested published answers only, which they can read on the public help site.
    requires_permission 'ticket.agent'
    requires_enabled_setting 'ai_provider'

    def resolve(ticket:, include_drafts_and_archived:, include_linked_answers:)
      raise Exceptions::UnprocessableContent, __('Knowledge base vector search is not available.') if !Service::AI::VectorDB::Available.execute

      Service::Ticket::AI::RelatedKnowledgeBaseAnswers
        .with_current_user(context.current_user)
        .execute(ticket:, include_drafts_and_archived:, include_linked_answers:)
    end
  end
end
