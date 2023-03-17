# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class SearchResultType < BaseUnion
    description 'Objects found by search'
    possible_types Gql::Types::TicketType, Gql::Types::UserType, Gql::Types::OrganizationType

    SEARCHABLE_MODELS = [::Ticket, ::User, ::Organization].freeze

    # TODO: static list for now. Change this to Models.searchable when there is full support from GraphQL types.
    def self.searchable_models
      SEARCHABLE_MODELS
    end
  end
end
