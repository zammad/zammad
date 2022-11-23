# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input
  class AutocompleteSearchOrganizationInputType < AutocompleteSearchInputType

    description 'The default fields for organization autocomplete searches.'

    argument :customer_id, GraphQL::Types::ID, required: false, description: 'Customer ID to filter the organizations by', loads: Gql::Types::UserType
  end
end
