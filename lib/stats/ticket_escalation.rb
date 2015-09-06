# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

class Stats::TicketEscalation

  def self.generate(user)

    # get users groups
    group_ids = user.groups.map(&:id)

    # owned tickets
    own_escalated = Ticket.where(
      owner_id: user.id,
      group_id: group_ids,
      escalation_time: Time.zone.now,
      state_id: Ticket::State.by_category('open').map(&:id)
    ).count

    # all tickets
    all_escalated = Ticket.where(
      owner_id: user.id,
      group_id: group_ids,
      escalation_time: Time.zone.now,
      state_id: Ticket::State.by_category('open').map(&:id)
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
