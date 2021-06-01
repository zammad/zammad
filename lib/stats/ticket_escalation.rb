# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Stats::TicketEscalation

  def self.generate(user)

    open_state_ids = Ticket::State.by_category(:open).pluck(:id)

    # get users groups
    group_ids = user.group_ids_access('full')

    # owned tickets
    own_escalated = Ticket.where(
      'owner_id = ? AND group_id IN (?) AND state_id IN (?) AND escalation_at < ?', user.id, group_ids, open_state_ids, Time.zone.now
    ).count

    # all tickets
    all_escalated = Ticket.where(
      'group_id IN (?) AND state_id IN (?) AND escalation_at < ?', group_ids, open_state_ids, Time.zone.now
    ).count

    average = '-'
    state = if own_escalated.zero?
              'supergood'
            elsif own_escalated <= 1
              'good'
            elsif own_escalated <= 4
              'ok'
            else
              'bad'
            end

    {
      used_for_average:  own_escalated,
      average_per_agent: average,
      state:             state,
      own:               own_escalated,
      total:             all_escalated,
    }
  end

  def self.average_state(result, _user_id)
    result
  end

end
