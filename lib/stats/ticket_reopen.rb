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
      used_for_average: 0,
      average_per_agent: '-',
      state: 'good',
      own: count,
      total: 0,
      percent: 0,
      its_me: true,
    }
  end

  def self.average_state(result, _user_id)

    return result if !result.key?(:used_for_average)

    if result[:total] < 1
      result[:state] = 'supergood'
      return result
    end

    in_percent = ( result[:used_for_average].to_f / (result[:total].to_f/100) ).round(1)
    if in_percent >= 90
      result[:state] = 'supergood'
    elsif in_percent >= 65
      result[:state] = 'good'
    elsif in_percent >= 40
      result[:state] = 'ok'
    elsif in_percent >= 20
      result[:state] = 'bad'
    else
      result[:state] = 'superbad'
    end

    result
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
