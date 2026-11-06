# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The color of a ticket's state icon in the desktop view: escalating, open, pending or closed.
class Service::Ticket::StateColorCode < Service::Base
  attr_reader :ticket

  def initialize(ticket:)
    @ticket = ticket
  end

  def execute
    return 'escalating' if escalating?

    case state_type_name
    when 'new', 'open'      then 'open'
    when 'pending reminder' then over_pending_time? ? 'open' : 'pending'
    when 'pending action'   then 'pending'
    else 'closed'
    end
  end

  private

  def escalating?
    ticket.escalation_at && ticket.escalation_at < Time.zone.now
  end

  def over_pending_time?
    ticket.pending_time && ticket.pending_time < Time.zone.now
  end

  def state_type_name
    ticket.state.state_type.name
  end
end
