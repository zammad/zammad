# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::AutocompleteSearch
  class TagInputType < InputType

    description 'Input fields for tag autocomplete searches.'

    argument :except_tags, [String], required: false, description: 'Optional tags to be filtered out from results'
  end
end
