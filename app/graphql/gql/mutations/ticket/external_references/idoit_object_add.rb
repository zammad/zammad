# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::ExternalReferences::IdoitObjectAdd < BaseMutation
    description 'Add idoit objects to a ticket or just resolve them for ticket creation.'

    argument :ticket_id,        GraphQL::Types::ID, required: false, loads: Gql::Types::TicketType, loads_pundit_method: :agent_update_access?, description: 'The related ticket for the idoit objects'
    argument :idoit_object_ids, [Integer], description: 'The idoit objects to add'

    field :idoit_objects, [Gql::Types::Ticket::ExternalReferences::IdoitObjectType], description: 'The added / resolved idoit objects'

    requires_enabled_setting 'idoit_integration', error_message: __('i-doit integration is not enabled')

    def authorized?(idoit_object_ids:, ticket: nil)
      ticket.present? || context.current_user.permissions?('ticket.agent')
    end

    def resolve(idoit_object_ids:, ticket: nil)
      results = []
      existing_ids = ticket&.preferences&.dig(:idoit, :object_ids) || []

      idoit_object_ids.each do |idoit_object_id|
        if existing_ids.include?(idoit_object_id)
          return error_response({ field: :idoit_object_ids, message: __('The idoit object is already present on the ticket.') })
        end

        api_object = Idoit.query('cmdb.objects', { ids: [idoit_object_id] })['result'].first

        if !api_object
          return error_response({ field: :idoit_object_ids, message: __('The idoit object could not be found.') })
        end

        results.push api_object
      end

      if ticket.present?
        ticket.preferences[:idoit] ||= {}
        ticket.preferences[:idoit][:object_ids] ||= []
        ticket.preferences[:idoit][:object_ids].push(*idoit_object_ids)
        ticket.save!
      end

      { idoit_objects: results }
    end
  end
end
