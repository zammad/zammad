# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class TicketEscalationRebuildJob < ApplicationJob
  include HasActiveJobLock

  def perform
    scope.in_batches.each_record do |ticket|
      ticket.escalation_calculation(true)
    end
  end

  private

  def scope
    Ticket.where(state_id: Ticket::State.by_category(:open))
  end

end
