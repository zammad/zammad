# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class Search::CountsResultType < Gql::Types::BaseObject
    description 'Search count results'

    field :model, Gql::Types::Enum::SearchableModelsType, null: false, description: 'Model that was searched in'
    field :total_count, Integer, null: false, description: 'Total count of found entries for the current model'
  end
end
