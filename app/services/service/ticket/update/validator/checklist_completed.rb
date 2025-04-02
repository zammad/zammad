# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::Update::Validator
  class ChecklistCompleted < Base

    def valid!
      return if !ticket.checklist
      return if ticket.checklist.completed?
      return if !ticket_closed? && !ticket_pending_close?

      raise Error
    end

    class Error < Service::Ticket::Update::Validator::BaseError
      def initialize
        super(__('The ticket checklist is incomplete.'))
      end
    end

    private

    def ticket_closed?
      return false if !ticket_data[:state]

      ticket_data[:state].state_type.name == 'closed'
    end

    def ticket_pending_close?
      return false if !ticket_data[:state]

      ticket_data[:state].state_type.name == 'pending action' && ticket_data[:state].next_state.state_type.name == 'closed'
    end
  end
end
