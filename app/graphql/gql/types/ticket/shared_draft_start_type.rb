# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Ticket
  class SharedDraftStartType < Gql::Types::BaseObject
    include Gql::Types::Concerns::HasDefaultModelFields
    include Gql::Types::Concerns::HasScopedModelUserRelations
    include Gql::Types::Concerns::HasInternalIdField
    include Gql::Types::Concerns::HasPunditAuthorization

    description 'Ticket shared draft to start new tickets'

    belongs_to :group, Gql::Types::GroupType

    field :name, String
    field :content, ::GraphQL::Types::JSON, method: :content_with_body_urls
  end
end
