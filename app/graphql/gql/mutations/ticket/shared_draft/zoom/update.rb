# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::SharedDraft::Zoom::Update < BaseMutation
    description 'Update ticket shared draft in detail view'

    argument :shared_draft_id, GraphQL::Types::ID,
             loads:       Gql::Types::Ticket::SharedDraftZoomType,
             description: 'The draft to be updated'

    argument :input, Gql::Types::Input::Ticket::SharedDraft::ZoomInputType, description: 'Draft content'

    field :shared_draft, Gql::Types::Ticket::SharedDraftZoomType, null: false, description: 'The updated draft.'

    def resolve(shared_draft:, input:)
      Service::Ticket::SharedDraft::Zoom::Update
        .new(
          context.current_user, input.form_id, shared_draft,
          new_article: input.new_article, ticket_attributes: input.ticket_attributes
        )
        .execute

      { shared_draft: }
    end
  end
end
