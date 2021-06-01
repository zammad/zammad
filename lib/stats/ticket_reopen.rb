# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Stats::TicketReopen

  def self.generate(user)

    # get my closed tickets
    total = Ticket.select('id').where(
      'owner_id = ? AND close_at > ?',
      user.id, Time.zone.now - 7.days
    ).count

    # get count of reopens
    count = StatsStore.where(
      stats_storable: user,
      key:            'ticket:reopen',
    ).where('created_at > ? AND created_at < ?', 7.days.ago, Time.zone.now).count

    if count > total
      total = count
    end

    reopen_in_precent = 0
    if total.nonzero?
      reopen_in_precent = ( count.to_f / (total.to_f / 100) ).round(1)
    end
    {
      used_for_average:  reopen_in_precent,
      percent:           reopen_in_precent,
      average_per_agent: '-',
      state:             'good',
      count:             count,
      total:             total,
    }
  end

  def self.average_state(result, _user_id)

    return result if !result.key?(:used_for_average)

    if result[:total] < 1 || result[:average_per_agent].to_d == 0.0.to_d
      result[:state] = 'supergood'
      return result
    end

    #in_percent = ( result[:used_for_average].to_f / (result[:average_per_agent].to_f / 100) ).round(1)
    #result[:average_per_agent_in_percent] = in_percent
    in_percent = ( result[:count].to_f / (result[:total].to_f / 100) ).round(1)
    result[:state] = if in_percent >= 90
                       'superbad'
                     elsif in_percent >= 65
                       'bad'
                     elsif in_percent >= 40
                       'ok'
                     elsif in_percent >= 20
                       'good'
                     else
                       'supergood'
                     end
    result
  end

  def self.log(object, o_id, changes, updated_by_id)
    return if object != 'Ticket'

    ticket = Ticket.lookup(id: o_id)
    return if !ticket

    # check if close_at is already set / if not, ticket is not reopened
    return if !ticket.close_at

    # only if state id has changed
    return if !changes['state_id']

    # only if ticket is not created in closed state
    return if !changes['state_id'][0]

    # only if current owner is not 1
    return if ticket.owner_id == 1

    state_before      = Ticket::State.lookup(id: changes['state_id'][0])
    state_type_before = Ticket::StateType.lookup(id: state_before.state_type_id)
    return if state_type_before.name != 'closed'

    state_now      = Ticket::State.lookup(id: changes['state_id'][1])
    state_type_now = Ticket::StateType.lookup(id: state_now.state_type_id)
    return if state_type_now.name == 'closed'

    StatsStore.create(
      stats_storable: ticket.owner,
      key:            'ticket:reopen',
      data:           { ticket_id: ticket.id },
      created_at:     Time.zone.now,
      created_by_id:  updated_by_id,
    )
  end

end
