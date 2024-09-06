# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::Update::Validator
  class ChecklistCompleted < Base

    def validate!
      return if !ticket.checklist
      return if ticket.checklist.completed?
      return if !ticket_closed? && !ticket_pending_close?

      raise IncompleteChecklistError
    end

    class IncompleteChecklistError < StandardError
      def initialize
        super(__('The ticket checklist is incomplete.'))
      end
    end

    private

    def ticket_closed?
      ticket_data[:state].state_type.name == 'closed'
    end

    def ticket_pending_close?
      ticket_data[:state].state_type.name == 'pending action' && ticket_data[:state].next_state.state_type.name == 'closed'
    end
  end
end
