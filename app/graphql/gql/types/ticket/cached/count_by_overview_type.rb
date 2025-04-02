# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Ticket
  class Cached::CountByOverviewType < Gql::Types::BaseObject

    description 'Represents the ticket count for an overview'

    field :overview, Gql::Types::OverviewType, null: false
    field :count, Integer, null: false
  end
end
