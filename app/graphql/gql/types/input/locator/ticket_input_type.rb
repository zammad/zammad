# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::Locator
  class TicketInputType < BaseLocator
    description 'Locate a ticket via id, internalId or number.'

    # Additional argument :ticket_number for this locator
    def self.init_arguments
      super
      argument :ticket_number, String, required: false, description: 'Ticket number'
    end

    def self.init_validators
      validates required: { one_of: [id_field_name, internal_id_field_name, :ticket_number] }
    end

    klass ::Ticket

    def find_record
      if ticket_number
        return ::Ticket.find_by(number: ticket_number) || raise(ActiveRecord::RecordNotFound, "The ticket ##{ticket_number} could not be found.")
      end

      super
    end
  end
end
