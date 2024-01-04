# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::AutocompleteSearch
  class RecipientEntryType < EntryType
    description 'Type that represents an autocomplete recipient entry.'

    field :user, Gql::Types::UserType, null: false
  end
end
