# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class SearchResultType < Gql::Types::BaseObject
    description 'Search result for one model'

    field :total_count, Integer, null: false, description: 'Total count of found entries across all pages'
    field :items, [Gql::Types::SearchResult::ItemType, { null: false }], null: false, description: 'Found items'
  end
end
