# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input
  class TicketLocatorInputType < Gql::Types::BaseInputObject

    description 'Locate a ticket via id, internalId or number.'

    argument :ticket_id, GraphQL::Types::ID, required: false, description: 'Ticket ID'
    argument :ticket_internal_id, Integer, required: false, description: 'Ticket internalId'
    argument :ticket_number, String, required: false, description: 'Ticket number'

    validates required: { one_of: %i[ticket_id ticket_internal_id ticket_number] }

    def prepare
      super
      find_ticket.tap do |ticket|
        Pundit.authorize(context.current_user, ticket, :show?)
      rescue Pundit::NotAuthorizedError => e
        raise Exceptions::Forbidden, e.message
      end
    end

    def find_ticket
      if ticket_internal_id
        return ::Ticket.find_by(id: ticket_internal_id) || raise(ActiveRecord::RecordNotFound, "The ticket #{ticket_internal_id} could not be found.")
      end

      if ticket_number
        return ::Ticket.find_by(number: ticket_number) || raise(ActiveRecord::RecordNotFound, "The ticket ##{ticket_number} could not be found.")
      end

      Gql::ZammadSchema.verified_object_from_id(ticket_id, type: ::Ticket)
    end
  end
end
