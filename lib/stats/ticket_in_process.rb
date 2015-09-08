# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

class Stats::TicketInProcess

  def self.generate(user)

    open_state_ids = Ticket::State.by_category('work_on').map(&:id)
    pending_state_ids = Ticket::State.by_category('pending_reminder').map(&:id)

    # get history entries of tickets worked on today
    history_object = History::Object.lookup(name: 'Ticket')

    # get own tickets which are "workable"
    own_ticket_ids = Ticket.select('id').where(
      'owner_id = ? AND (state_id IN (?) OR (state_id IN (?) AND pending_time < ?))',
      user.id, open_state_ids, pending_state_ids, Time.zone.now
    ).limit(1000).map(&:id)

    # get all tickets where I worked on today (owner & closed today)
    closed_state_ids = Ticket::State.by_category('closed').map(&:id)
    closed_ticket_ids = Ticket.select('id').where(
      'owner_id = ? AND state_id IN (?) AND close_time > ?',
      user.id, closed_state_ids, Time.zone.now-1.day
    ).limit(100).map(&:id)

    # get all tickets which I changed to pending action
    pending_action_state_ids = Ticket::State.by_category('pending_action').map(&:id)
    pending_action_ticket_ids = Ticket.select('id').where(
      'owner_id = ? AND state_id IN (?) AND updated_at > ?',
      user.id, pending_action_state_ids, Time.zone.now-1.day
    ).limit(100).map(&:id)

    all_ticket_ids = own_ticket_ids.concat(closed_ticket_ids).concat(pending_action_ticket_ids).uniq

    # get count where user worked on
    count = History.select('DISTINCT(o_id)').where(
      'histories.created_at >= ? AND histories.history_object_id = ? AND histories.created_by_id = ? AND histories.o_id IN (?)', Time.zone.now - 1.day, history_object.id, user.id, all_ticket_ids
    ).count

    total = all_ticket_ids.count
    in_process_precent = 0
    state = 'supergood'
    average_in_percent = '-'

    if total != 0
      in_process_precent = (count * 1000) / ((total * 1000) / 100)
      if in_process_precent >= 75
        state = 'supergood'
      elsif in_process_precent >= 55
        state = 'good'
      elsif in_process_precent >= 40
        state = 'ok'
      elsif in_process_precent >= 20
        state = 'bad'
      else
        state = 'superbad'
      end
    end

    {
      used_for_average: in_process_precent,
      average_per_agent: average_in_percent,
      state: state,
      in_process: count,
      percent: in_process_precent,
      total: total,
    }
  end

end
