# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Ticket::Checklist < BaseQuery
    description 'Fetch ticket checklist'

    argument :ticket_id, ID, loads: Gql::Types::TicketType, description: 'Ticket ID'

    type Gql::Types::ChecklistType, null: true

    requires_enabled_setting 'checklist', error_message: __('The checklist feature is not active')
    requires_permission 'ticket.agent'

    def resolve(ticket:)
      ::Checklist.find_by(ticket:)
    end
  end
end
