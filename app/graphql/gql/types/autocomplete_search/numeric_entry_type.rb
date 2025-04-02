# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::AutocompleteSearch
  class NumericEntryType < EntryType

    description 'Type that represents an autocomplete entry with a numeric value.'

    field :value, Integer, null: false
  end
end
