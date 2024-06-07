# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::AutocompleteSearch
  class UserInputType < InputType

    description 'Input fields for user autocomplete searches.'

    argument :except_internal_id, Integer, required: false, description: 'Optional user ID to be filtered out from results'
  end
end
