# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum::KnowledgeBase
  class VisibilityType < Gql::Types::Enum::BaseEnum
    description 'Publication state used for color-coding knowledge base content'

    # The values mirror the `CanBePublished` state-machine states, so a model's
    #   `#visibility` symbol maps straight onto this enum with no translation.
    value 'draft', 'Not yet published (grey).', value: :draft
    value 'internal', 'Published internally, visible to agents (blue).', value: :internal
    value 'published', 'Published publicly (green).', value: :published
    value 'archived', 'No longer published, retained for reference.', value: :archived
  end
end
