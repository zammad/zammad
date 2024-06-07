# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::AutocompleteSearch
  class GenericInputType < InputType

    description 'Input fields for generic autocomplete searches.'

    argument :only_in, [Gql::Types::Enum::SearchableModelsType], required: false, description: 'Optionally restrict search certain models'
  end
end
