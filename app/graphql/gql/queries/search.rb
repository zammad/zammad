# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Search < BaseQuery

    description 'Generic object search'

    argument :search,  String, description: 'What to search for'
    argument :only_in, Gql::Types::Enum::SearchableModelsType, required: false, description: 'Optionally restrict search to only_in one model'
    argument :limit,   Integer, required: false, description: 'How many entries to find at maximum per model'

    type [Gql::Types::SearchResultType, { null: false }], null: false

    def resolve(search:, only_in: nil, limit: 10)
      Service::Search.new(current_user: context.current_user).execute(
        term:    search,
        objects: only_in ? [only_in] : Gql::Types::SearchResultType.searchable_models,
        options: { limit: limit }
      )
    end
  end
end
