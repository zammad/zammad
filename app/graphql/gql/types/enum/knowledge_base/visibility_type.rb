# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum::KnowledgeBase
  class VisibilityType < Gql::Types::Enum::BaseEnum
    description 'Publication state used for color-coding knowledge base content'

    value 'draft', 'Not yet published (grey).'
    value 'internal', 'Published internally, visible to agents (blue).'
    value 'public', 'Published publicly (green).'
  end
end
