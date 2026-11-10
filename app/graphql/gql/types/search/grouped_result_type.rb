# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class Search::GroupedResultType < Gql::Types::BaseObject
    description 'Search results for one model'

    field :model, Gql::Types::Enum::SearchableModelsType, null: false, description: 'Model that was searched in'
    field :total_count, Integer, null: false, description: 'Total count of found entries for the current model'
    field :items, [Gql::Types::SearchResult::ItemType, { null: false }], null: false, description: 'Found items, up to the requested limit'
  end
end
