# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::AutocompleteSearch
  class UserEntryType < NumericEntryType
    description 'Type that represents an autocomplete user entry.'

    field :user, Gql::Types::UserType, null: false
  end
end
