# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class AutocompleteUserEntryType < AutocompleteEntryType
    description 'Type that represents an autocomplete user entry.'

    field :user, Gql::Types::UserType, null: false
  end
end
