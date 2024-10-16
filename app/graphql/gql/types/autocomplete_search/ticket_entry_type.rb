# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::AutocompleteSearch
  class TicketEntryType < EntryType
    description 'Type that represents an autocomplete ticket entry.'

    field :ticket, Gql::Types::TicketType, null: false
  end
end
