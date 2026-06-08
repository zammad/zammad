# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class Ticket::ChecklistUpdates < BaseSubscription

    description 'Subscription for ticket checklist changes.'

    argument :ticket_id, GraphQL::Types::ID, loads: Gql::Types::TicketType, description: 'Ticket identifier'

    field :ticket_checklist, Gql::Types::ChecklistType, description: 'Ticket checklist'
    field :removed_ticket_checklist, Boolean, description: 'Ticket checklist was removed from ticket'

    requires_enabled_setting 'checklist', error_message: __('The checklist feature is not active')
    requires_permission 'ticket.agent'

    def update(ticket:)
      return { removed_ticket_checklist: true } if object.nil?

      { ticket_checklist: object }
    end
  end
end
