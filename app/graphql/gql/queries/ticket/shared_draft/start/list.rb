# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Ticket::SharedDraft::Start::List < BaseQuery

    description 'Ticket shared drafts available to start new ticket in a given group'

    argument :group_id, GraphQL::Types::ID,
             loads:               Gql::Types::GroupType,
             loads_pundit_method: :create_tickets?,
             description:         'A group to filter by'

    type [Gql::Types::Ticket::SharedDraftStartType], null: false

    def resolve(group:)
      if !group.shared_drafts
        raise __('Shared drafts are not activated for the selected group')
      end

      ::Ticket::SharedDraftStartPolicy::Scope
        .new(context.current_user, ::Ticket::SharedDraftStart)
        .resolve
        .where(group_id: group)
        .reorder(updated_at: :desc)
    end
  end
end
