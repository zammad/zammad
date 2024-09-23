# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::SharedDraft::Zoom::Delete < BaseMutation
    description 'Deletes ticket shared draft'

    argument :shared_draft_id, GraphQL::Types::ID, loads: Gql::Types::Ticket::SharedDraftZoomType, description: 'The draft to be deleted'

    field :success, Boolean, null: false, description: 'Was the ticket article deletion successful?'

    def authorized?(shared_draft:)
      Pundit.authorize(context.current_user, shared_draft, :destroy?)
    end

    def resolve(shared_draft:)
      shared_draft.destroy!

      { success: true }
    end
  end
end
