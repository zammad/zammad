# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::AutocompleteSearch
  class KnowledgeBaseCategoryIconInputType < InputType

    description 'Input fields for knowledge base category icon autocomplete searches.'

    argument :icon_set, Gql::Types::KnowledgeBase::IconSetType, required: true, description: 'Icon font of the knowledge base the category belongs to, selecting the catalog to search'
  end
end
