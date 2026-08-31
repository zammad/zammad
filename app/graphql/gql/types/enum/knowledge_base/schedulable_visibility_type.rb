# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum::KnowledgeBase
  # The publication states a transition can be *scheduled* to reach: Gql::Types::Enum::KnowledgeBase
  #   ::VisibilityType minus `draft`. A state is stored as the date it was reached at, and `draft` is
  #   what no date at all means — there is nothing to put in the future for it, and nothing that
  #   would fire.
  #
  # An own enum rather than the full one with a check in the service: which states can be scheduled
  #   is a property of the schema, and the flyout that offers them reads its options from it.
  class SchedulableVisibilityType < Gql::Types::Enum::BaseEnum
    description 'Publication state a scheduled visibility change of knowledge base content can reach'

    # The values mirror the `CanBePublished` state-machine states, so a state symbol maps straight
    #   onto this enum with no translation — the same as VisibilityType.
    value 'internal', 'Published internally, visible to agents.', value: :internal
    value 'published', 'Published publicly.', value: :published
    value 'archived', 'No longer published, retained for reference.', value: :archived
  end
end
