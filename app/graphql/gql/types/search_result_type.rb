# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class SearchResultType < BaseUnion
    description 'Objects found by search'
    possible_types Gql::Types::TicketType, Gql::Types::UserType, Gql::Types::OrganizationType
  end
end
