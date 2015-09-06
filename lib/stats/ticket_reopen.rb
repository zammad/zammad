# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

class Stats::TicketReopen

  def self.generate(user)
    count = StatsStore.count_by_search(
      object: 'User',
      o_id:   user.id,
      key:    'ticket:reopen',
      start:  Time.zone.now - 7.days,
      end:    Time.zone.now,
    )
    {
      state: 'good',
      own: count,
      total: 0,
      percent: 0,
      average_percent: '-',
    }
  end

  def self.log(object, o_id, changes, updated_by_id)
    return if object != 'Ticket'
    ticket = Ticket.lookup(id: o_id)

    # check if close_time is already set / if not, ticket is not reopend
    return if !ticket.close_time

    return if !changes['state_id']
    return if ticket.owner_id == 1

    state_before      = Ticket::State.lookup(id: changes['state_id'][0])
    state_type_before = Ticket::StateType.lookup(id: state_before.state_type_id)
    return if state_type_before.name != 'closed'

    state_now      = Ticket::State.lookup(id: changes['state_id'][1])
    state_type_now = Ticket::StateType.lookup(id: state_now.state_type_id)
    return if state_type_now.name == 'closed'

    StatsStore.add(
      object: 'User',
      o_id: ticket.owner_id,
      key: 'ticket:reopen',
      data: { ticket_id: ticket.id },
      created_at: Time.zone.now,
      created_by_id: updated_by_id,
      updated_by_id: updated_by_id,
    )
  end

end
