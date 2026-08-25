# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::KnowledgeBase
  class VisibilityInputType < Gql::Types::BaseInputObject
    description 'Represents the publication state of a knowledge base object and when it takes effect.'

    # The two belong together: the state says which timestamp column CanBePublished derives it from,
    #   and the date says what goes into that column. Kept as one object rather than as a pair of
    #   flat arguments so a date without a state — which has nothing to be a date *of* — cannot be
    #   submitted in the first place.
    #
    # The same shape the legacy publication dialog submits, minus its `timing` radio: 'now' is what
    #   an absent date means here.
    argument :state, Gql::Types::Enum::KnowledgeBase::VisibilityType, description: 'Publication state to put the object in. `draft` leaves it unpublished.'

    argument :scheduled_at, GraphQL::Types::ISO8601DateTime, required: false, description: 'When the state takes effect. Omitted means immediately; a future point in time keeps the object a draft until then.'
  end
end
