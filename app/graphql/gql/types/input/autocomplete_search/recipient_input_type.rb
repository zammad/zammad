# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::AutocompleteSearch
  class RecipientInputType < UserInputType

    description 'Input fields for recipient autocomplete searches.'

    argument :contact, Gql::Types::Enum::UserContactType, required: false, description: 'User contact type option, i.e. email or phone'
  end
end
