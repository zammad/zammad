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

    # get count where user worked on
    count = History.select('DISTINCT(o_id)').where(
      'histories.created_at >= ? AND histories.history_object_id = ? AND histories.created_by_id = ? AND histories.o_id IN (?)', Time.zone.now - 1.day, history_object.id, user.id, own_ticket_ids
    ).count

    total = own_ticket_ids.count
    in_process_precent = 0
    state = 'supergood'
    average_in_percent = '-'

    if total != 0
      in_process_precent = (count * 1000) / ((total * 1000) / 100)
      if in_process_precent > 80
        state = 'supergood'
      elsif in_process_precent > 60
        state = 'good'
      elsif in_process_precent > 40
        state = 'ok'
      elsif in_process_precent > 20
        state = 'bad'
      else
        state = 'superbad'
      end
    end

    {
      state: state,
      in_process: count,
      percent: in_process_precent,
      average_percent: average_in_percent,
      total: total,
    }
  end

end
