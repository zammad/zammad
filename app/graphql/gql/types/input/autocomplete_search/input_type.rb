# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::AutocompleteSearch
  class InputType < Gql::Types::BaseInputObject

    description 'The default fields for autocomplete searches.'

    argument :query, String, description: 'Query from the autocomplete field'
    argument :limit, Integer, required: false, description: 'Limit for the amount of entries'
  end
end
