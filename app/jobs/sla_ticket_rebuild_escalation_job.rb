class SlaTicketRebuildEscalationJob < ApplicationJob
  include HasActiveJobLock

  def perform
    Cache.delete('SLA::List::Active')
    Ticket::Escalation.rebuild_all
  end
end
