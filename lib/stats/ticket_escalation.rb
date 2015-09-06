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
    #  if in_process_precent > 80
    #    state = 'supergood'
    #  elsif in_process_precent > 60
    #    state = 'good'
    #  elsif in_process_precent > 40
    #    state = 'ok'
    #  elsif in_process_precent > 20
    #    state = 'bad'
    #  elsif in_process_precent > 5
    #    state = 'superbad'
    #  end

    {
      average: average,
      state: state,
      own: own_escalated,
      total: all_escalated,
    }
  end

end
