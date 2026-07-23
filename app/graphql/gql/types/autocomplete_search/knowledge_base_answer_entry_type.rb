# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::AutocompleteSearch
  class KnowledgeBaseAnswerEntryType < EntryType

    description 'Type that represents an autocomplete knowledge base answer entry.'

    field :visibility, Gql::Types::Enum::KnowledgeBase::VisibilityType, null: false, description: 'Publication state, used for the state icon in the picker'
  end
end
