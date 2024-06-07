# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::AutocompleteSearch
  class OrganizationInputType < InputType

    description 'Input fields for organization autocomplete searches.'

    argument :customer_id, GraphQL::Types::ID, required: false, description: 'Customer ID to filter the organizations by', loads: Gql::Types::UserType
  end
end
