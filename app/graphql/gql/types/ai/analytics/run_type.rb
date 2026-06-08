# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::AI::Analytics
  class RunType < Gql::Types::BaseObject
    include Gql::Types::Concerns::IsModelObject
    include Gql::Types::Concerns::HasInternalIdField
    include Gql::Types::Concerns::HasPunditAuthorization

    description 'AI::Analytics::Run identifies an AI result that can be used for analytics purposes.'

    field :related_object, Gql::Types::TicketType, null: true, description: 'The ticket related to this AI result.'
  end
end
