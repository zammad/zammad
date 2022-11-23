# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class AutocompleteOrganizationEntryType < AutocompleteEntryType
    description 'Type that represents an autocomplete organization entry.'

    field :organization, Gql::Types::OrganizationType, null: false
  end
end
