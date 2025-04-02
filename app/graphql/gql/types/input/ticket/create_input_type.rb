# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::Ticket
  class CreateInputType < BaseInputType
    description 'Represents the ticket attributes to be used in ticket create.'

    only_for_ticket_agents = lambda do |payload, context|
      context.current_user.permissions?('ticket.agent') ? payload : BaseInputType::ArgumentFilteredOut.new
    end

    # Arguments required for create.
    argument :group_id, GraphQL::Types::ID, description: 'The group of the ticket.', loads: Gql::Types::GroupType
    argument :title, Gql::Types::NonEmptyStringType, description: 'The title of the ticket.'

    # Arguments specific to create.
    argument :tags, [String], required: false, description: 'The tags that should be assigned to the new ticket.', prepare: only_for_ticket_agents

    argument :shared_draft_id,
             GraphQL::Types::ID,
             required:    false,
             description: 'The shared draft used to create this ticket.',
             loads:       Gql::Types::Ticket::SharedDraftStartType,
             prepare:     only_for_ticket_agents

    argument :links,
             [Gql::Types::Input::Ticket::LinkInputType],
             required:    false,
             description: 'Links to create for the newly created ticket',
             prepare:     only_for_ticket_agents

    argument :external_references,
             Gql::Types::Input::Ticket::ExternalReferencesInputType,
             required:    false,
             description: 'External references to create for the newly created ticket',
             prepare:     only_for_ticket_agents
  end
end
