# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::ExternalReferences::IdoitUpObjectAdd < BaseMutation
    description 'Add i-doit up objects to a ticket or just resolve them for ticket creation.'

    argument :ticket_id,           GraphQL::Types::ID, required: false, loads: Gql::Types::TicketType, loads_pundit_method: :agent_update_access?, description: 'The related ticket for the i-doit up objects'
    argument :idoit_up_object_ids, [String], description: 'The i-doit up objects to add'

    field :idoit_up_objects, [Gql::Types::Ticket::ExternalReferences::IdoitUpObjectType], description: 'The added / resolved i-doit up objects'

    requires_enabled_setting 'idoit_up_integration', error_message: __('i-doit up integration is not enabled')

    def authorized?(idoit_up_object_ids:, ticket: nil)
      ticket.present? || context.current_user.permissions?('ticket.agent')
    end

    def resolve(idoit_up_object_ids:, ticket: nil)
      results = []
      existing_ids = (ticket&.preferences&.dig(:idoit_up, :object_ids) || []).map(&:to_s)

      idoit_up_object_ids.each do |idoit_up_object_id|
        if existing_ids.include?(idoit_up_object_id)
          return error_response({ field: :idoit_up_object_ids, message: __('The i-doit up object is already present on the ticket.') })
        end

        api_object = IdoitUp.query('cmdb.objects', { ids: [idoit_up_object_id] }, user: context.current_user)['result'].first

        if !api_object
          return error_response({ field: :idoit_up_object_ids, message: __('The i-doit up object could not be found.') })
        end

        results.push api_object
      end

      if ticket.present?
        ticket.preferences[:idoit_up] ||= {}
        ticket.preferences[:idoit_up][:object_ids] ||= []
        ticket.preferences[:idoit_up][:object_ids].push(*idoit_up_object_ids)
        ticket.save!
      end

      { idoit_up_objects: results }
    end
  end
end
