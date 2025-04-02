# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Ticket
  class SharedDraftZoomType < Gql::Types::BaseObject
    include Gql::Types::Concerns::HasDefaultModelFields
    include Gql::Types::Concerns::HasScopedModelUserRelations
    include Gql::Types::Concerns::HasInternalIdField
    include Gql::Types::Concerns::HasPunditAuthorization

    description 'Ticket shared draft in detail view'

    field :ticket_id, GraphQL::Types::ID
    field :new_article, ::GraphQL::Types::JSON, method: :content_with_body_urls
    field :ticket_attributes, ::GraphQL::Types::JSON

    def ticket_id
      Gql::ZammadSchema.id_from_object(object.ticket)
    end
  end
end
