# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class Ticket::SharedDraft::Start::UpdateByGroup < BaseSubscription
    description 'Updates to ticket records'

    argument :group_id, GraphQL::Types::ID,
             loads:               Gql::Types::GroupType,
             loads_pundit_method: :create_tickets?,
             description:         'A group to filter by'

    field :shared_draft_starts,
          [Gql::Types::Ticket::SharedDraftStartType, { null: false }],
          description: 'Up-to-date drafts in the given'

    def update(group:)
      drafts = ::Ticket::SharedDraftStartPolicy::Scope
        .new(context.current_user, ::Ticket::SharedDraftStart)
        .resolve
        .where(group_id: group)
        .reorder(updated_at: :desc)

      { shared_draft_starts: drafts }
    end
  end
end
