# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Ticket::SharedDraft::Zoom::Show < BaseQuery

    description 'Get a single ticket shared draft in detail view'

    argument :shared_draft_id, GraphQL::Types::ID,
             loads:       Gql::Types::Ticket::SharedDraftZoomType,
             description: 'The draft to get'

    type Gql::Types::Ticket::SharedDraftZoomType, null: false

    def resolve(shared_draft:)
      shared_draft
    end
  end
end
