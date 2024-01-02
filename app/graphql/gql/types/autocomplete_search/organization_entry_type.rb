# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::AutocompleteSearch
  class OrganizationEntryType < NumericEntryType
    description 'Type that represents an autocomplete organization entry.'

    field :organization, Gql::Types::OrganizationType, null: false
  end
end
