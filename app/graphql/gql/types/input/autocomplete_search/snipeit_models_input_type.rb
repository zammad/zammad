# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::AutocompleteSearch
  class SnipeitModelsInputType < InputType

    description 'Input fields for Snipe-IT model autocomplete searches.'

    argument :category_id, String, required: false, description: 'Snipe-IT category id to restrict the models to'
  end
end
