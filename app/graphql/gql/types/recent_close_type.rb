# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class RecentCloseType < BaseUnion
    description 'Recently closed object'
    possible_types Gql::Types::TicketType, Gql::Types::UserType, Gql::Types::OrganizationType
  end
end
