# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::SharedDraft::Zoom::Create < BaseMutation
    description 'Create ticket shared draft in detail view'

    argument :input, Gql::Types::Input::Ticket::SharedDraft::ZoomInputType, description: 'Draft content'

    field :shared_draft, Gql::Types::Ticket::SharedDraftZoomType, null: false, description: 'The created draft.'

    def resolve(input:)
      shared_draft = Service::Ticket::SharedDraft::Zoom::Create
        .new(
          context.current_user, input.form_id,
          ticket: input.ticket, new_article: input.new_article, ticket_attributes: input.ticket_attributes
        )
        .execute

      { shared_draft: }
    end
  end
end
