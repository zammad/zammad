# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::ExternalReferences::IdoitObjectAdd < BaseMutation
    description 'Add idoit objects to a ticket or just resolve them for ticket creation.'

    argument :ticket_id,        GraphQL::Types::ID, required: false, loads: Gql::Types::TicketType, description: 'The related ticket for the idoit objects'
    argument :idoit_object_ids, [Integer], description: 'The idoit objects to add'

    field :idoit_objects, [Gql::Types::Ticket::ExternalReferences::IdoitObjectType], description: 'The added / resolved idoit objects'

    def self.authorize(_obj, _ctx)
      Setting.get('idoit_integration')
    end

    def authorized?(idoit_object_ids:, ticket: nil)
      if ticket.present?
        Pundit.authorize(context.current_user, ticket, :agent_update_access?)
      else
        context.current_user.permissions?('ticket.agent')
      end
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
