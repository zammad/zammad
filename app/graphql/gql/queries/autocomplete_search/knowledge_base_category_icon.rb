# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class AutocompleteSearch::KnowledgeBaseCategoryIcon < BaseQuery
    requires_permission 'knowledge_base.editor'

    description 'Search for knowledge base category icons'

    argument :input, Gql::Types::Input::AutocompleteSearch::KnowledgeBaseCategoryIconInputType, required: true, description: 'The input object for the autocomplete search'

    type [Gql::Types::AutocompleteSearch::KnowledgeBaseCategoryIconEntryType], null: false

    def resolve(input:)
      icon_set = input.icon_set

      ::KnowledgeBase::IconCatalog
        .for(icon_set)
        .search(input.query, limit: input.limit)
        .map { coerce_to_result(it, icon_set) }
    end

    private

    def coerce_to_result(icon, icon_set)
      {
        value:    icon.unicode,
        label:    icon.name,
        icon_set: icon_set,
      }
    end
  end
end
