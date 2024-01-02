# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::AutocompleteSearch
  class ExternalDataSourceEntryType < Gql::Types::AutocompleteSearch::EntryType

    description 'Type that represents an autocomplete entry with an external data source value.'

    field :value, GraphQL::Types::JSON, null: false
  end
end
