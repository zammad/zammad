# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::Ticket
  class UpdateInputType < BaseInputType
    description 'Represents the ticket attributes to be used in ticket update.'

    # Arguments optional in update.
    argument :group_id, GraphQL::Types::ID, required: false, description: 'The group of the ticket.', loads: Gql::Types::GroupType
    argument :title, Gql::Types::NonEmptyStringType, required: false, description: 'The title of the ticket.'

    # Arguments specific to update.
    argument :shared_draft_id,
             GraphQL::Types::ID,
             required:    false,
             description: 'The shared draft used to update this ticket.',
             loads:       Gql::Types::Ticket::SharedDraftZoomType

    def self.agent_only_fields
      super + %w[shared_draft_id group_id]
    end
  end
end
