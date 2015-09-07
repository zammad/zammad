# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

class Stats::TicketEscalation

  def self.generate(user)

    open_state_ids = Ticket::State.by_category('open').map(&:id)

    # get users groups
    group_ids = user.groups.map(&:id)

    # owned tickets
    own_escalated = Ticket.where(
      'owner_id = ? AND group_id IN (?) AND state_id IN (?) AND escalation_time < ?', user.id, group_ids, open_state_ids, Time.zone.now
    ).count

    # all tickets
    all_escalated = Ticket.where(
      'group_id IN (?) AND state_id IN (?) AND escalation_time < ?', group_ids, open_state_ids, Time.zone.now
    ).count

    average = '-'
    state = 'supergood'
    if own_escalated == 0
      state = 'supergood'
    elsif own_escalated > 1
      state = 'good'
    elsif own_escalated > 2
      state = 'ok'
    elsif own_escalated > 5
      state = 'bad'
    else
      state = 'superbad'
    end

    {
      state: state,
      average: average,
      state: state,
      own: own_escalated,
      total: all_escalated,
    }
  end

end
