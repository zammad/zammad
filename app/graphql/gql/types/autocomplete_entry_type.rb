# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class AutocompleteEntryType < Gql::Types::BaseObject

    description 'Type that represents an autocomplete entry.'

    field :value, String, null: false
    field :label, String, null: false
    field :label_placeholder, [String], null: true
    field :heading, String, null: true
    field :heading_placeholder, [String], null: true
    field :disabled, Boolean, null: true
    field :icon, String, null: true
    # field :status?
  end
end
