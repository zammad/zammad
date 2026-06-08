# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::ExternalReferences::IdoitObjectRemove < BaseMutation
    description 'Remove an idoit object from a ticket.'

    argument :ticket_id, GraphQL::Types::ID, loads: Gql::Types::TicketType, loads_pundit_method: :agent_update_access?, description: 'The related ticket for the idoit objects'
    argument :idoit_object_id, Integer, description: 'The idoit object to remove'

    field :success, Boolean, description: 'Was the mutation successful?'

    requires_enabled_setting 'idoit_integration', error_message: __('i-doit integration is not enabled')

    def resolve(idoit_object_id:, ticket: nil)
      ticket.preferences.dig(:idoit, :object_ids)&.map!(&:to_i)&.delete(idoit_object_id)
      ticket.save!

      { success: true }
    end
  end
end
