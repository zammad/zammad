class SlaTicketRebuildEscalationJob < ApplicationJob
  def perform
    Cache.delete('SLA::List::Active')
    Ticket::Escalation.rebuild_all
  end
end
