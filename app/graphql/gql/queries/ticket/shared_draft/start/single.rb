# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Ticket::SharedDraft::Start::Single < BaseQuery

    description 'Ticket shared drafts available to start new ticket in a given group'

    argument :shared_draft_id, GraphQL::Types::ID,
             loads:       Gql::Types::Ticket::SharedDraftStartType,
             description: 'The draft to be updated'

    type Gql::Types::Ticket::SharedDraftStartType, null: false

    def resolve(shared_draft:)
      shared_draft
    end
  end
end
