# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::AutocompleteSearch
  class EntryType < Gql::Types::BaseObject

    description 'Type that represents an autocomplete entry with a string value.'

    field :value, String, null: false
    field :label, String, null: false
    field :label_placeholder, [String]
    field :heading, String
    field :heading_placeholder, [String]
    field :disabled, Boolean
    field :icon, String
    # field :status?
  end
end
