# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::SharedDraft::Start::Update < BaseMutation
    description 'Deletes ticket shared draft'

    argument :shared_draft_id, GraphQL::Types::ID,
             loads:       Gql::Types::Ticket::SharedDraftStartType,
             description: 'The draft to be updated'

    argument :input, Gql::Types::Input::Ticket::SharedDraft::StartInputType, description: 'Draft content'

    field :shared_draft, Gql::Types::Ticket::SharedDraftStartType, null: false, description: 'The updated draft.'

    def resolve(shared_draft:, input:)
      Service::Ticket::SharedDraft::Start::Update
        .new(context.current_user, shared_draft, input.form_id, group: input.group, content: input.content)
        .execute

      { shared_draft: }
    end
  end
end
