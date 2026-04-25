# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::SharedDraft::Start::Create < BaseMutation
    description 'Deletes ticket shared draft'

    argument :name, String, description: 'Name of the shared draft'
    argument :input, Gql::Types::Input::Ticket::SharedDraft::StartInputType, description: 'Draft content'

    field :shared_draft, Gql::Types::Ticket::SharedDraftStartType, null: false, description: 'The updated draft.'

    def resolve(name:, input:)
      shared_draft = Service::Ticket::SharedDraft::Start::Create
        .with_current_user(context.current_user)
        .execute(input.form_id, name: name, group: input.group, content: input.content)

      { shared_draft: }
    end
  end
end
