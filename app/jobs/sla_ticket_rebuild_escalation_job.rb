class SlaTicketRebuildEscalationJob < ApplicationJob
  def perform(_sla_id)
    Cache.delete('SLA::List::Active')
    Ticket::Escalation.rebuild_all
  end
end
