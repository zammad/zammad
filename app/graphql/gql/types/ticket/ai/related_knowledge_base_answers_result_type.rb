# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Ticket::AI
  class RelatedKnowledgeBaseAnswersResultType < Gql::Types::BaseObject
    description 'Result of a related knowledge base answers search for a ticket'

    field :answers, [Gql::Types::Ticket::AI::RelatedKnowledgeBaseAnswerType], null:        true,
                                                                              description: 'The related knowledge base answers, ordered by relevance. Null while the ticket summary is still being generated.'

    field :pending, Boolean, null:        false,
                             description: 'Whether the ticket summary the search relies on is still being generated. Subscribe to the ping and refetch when it arrives.'
  end
end
