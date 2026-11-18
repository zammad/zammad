# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::ExternalReferences::IdoitUpObjectRemove < BaseMutation
    description 'Remove an i-doit up object from a ticket.'

    argument :ticket_id, GraphQL::Types::ID, loads: Gql::Types::TicketType, loads_pundit_method: :agent_update_access?, description: 'The related ticket for the i-doit up objects'
    argument :idoit_up_object_id, String, description: 'The i-doit up object to remove'

    field :success, Boolean, description: 'Was the mutation successful?'

    requires_enabled_setting 'idoit_up_integration', error_message: __('i-doit up integration is not enabled')

    def resolve(idoit_up_object_id:, ticket: nil)
      ticket.preferences.dig(:idoit_up, :object_ids)&.map!(&:to_s)&.delete(idoit_up_object_id.to_s)
      ticket.save!

      { success: true }
    end
  end
end
