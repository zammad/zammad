class Observer::Sla::TicketRebuildEscalation::BackgroundJob
  def initialize(_sla_id)
  end

  def perform
    Cache.delete('SLA::List::Active')
    Ticket::Escalation.rebuild_all
  end
end
