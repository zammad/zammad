# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::AutocompleteSearch
  class KnowledgeBaseCategoryIconEntryType < EntryType

    description 'Type that represents an autocomplete knowledge base category icon entry. Its `value` is the codepoint stored on the category, which doubles as the sprite symbol id.'

    field :icon_set, Gql::Types::KnowledgeBase::IconSetType, null: false, description: 'Icon font the entry was found in, needed to render it from the correct sprite'
  end
end
