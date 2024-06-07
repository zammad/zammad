# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::AutocompleteSearch
  class GenericEntryType < NumericEntryType
    description 'Type that represents a generic autocomplete entry.'

    field :object, Gql::Types::SearchResultType, null: false, resolver_method: :resolve_object

    # Required because of conflicts with the built-in method 'object' of graphql-ruby.
    def resolve_object
      @object[:object]
    end
  end
end
