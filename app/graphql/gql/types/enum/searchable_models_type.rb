# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum
  class SearchableModelsType < BaseEnum
    description 'All searchable models'

    build_class_list_enum Gql::Types::SearchResultType.searchable_models
  end
end
