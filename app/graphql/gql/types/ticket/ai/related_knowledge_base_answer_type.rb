# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Ticket::AI
  class RelatedKnowledgeBaseAnswerType < Gql::Types::BaseObject
    description 'A knowledge base answer related to a ticket, found via vector similarity search'

    field :translation, Gql::Types::KnowledgeBase::Answer::TranslationType, null: false, description: 'The matching knowledge base answer translation'

    # TODO(PoC): raw similarity score, surfaced to the frontend for debugging/calibration. Revisit
    # how (or whether) to expose it before shipping — the raw value reads uniformly high for the
    # current embedding model, so a normalised relevance would be more meaningful.
    field :score, Float, null: false, description: 'Relevance score of the match (higher is more relevant)'
  end
end
