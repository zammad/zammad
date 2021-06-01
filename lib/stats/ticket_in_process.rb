# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Stats::TicketInProcess

  def self.generate(user)

    # get own tickets which are "workable"
    open_state_ids = Ticket::State.by_category(:work_on).pluck(:id)
    pending_state_ids = Ticket::State.by_category(:pending_reminder).pluck(:id)
    own_ticket_ids = Ticket.select('id').where(
      'owner_id = ? AND (state_id IN (?) OR (state_id IN (?) AND pending_time < ?))',
      user.id, open_state_ids, pending_state_ids, Time.zone.now
    ).limit(1000).pluck(:id)

    # get all tickets where I worked on today (owner & closed today)
    closed_state_ids = Ticket::State.by_category(:closed).pluck(:id)
    closed_ticket_ids = Ticket.select('id').where(
      'owner_id = ? AND state_id IN (?) AND close_at > ?',
      user.id, closed_state_ids, Time.zone.now - 1.day
    ).limit(100).pluck(:id)

    # get all tickets which I changed to pending action
    pending_action_state_ids = Ticket::State.by_category(:pending_action).pluck(:id)
    pending_action_ticket_ids = Ticket.select('id').where(
      'owner_id = ? AND state_id IN (?) AND updated_at > ?',
      user.id, pending_action_state_ids, Time.zone.now - 1.day
    ).limit(100).pluck(:id)

    all_ticket_ids = own_ticket_ids.concat(closed_ticket_ids).concat(pending_action_ticket_ids).uniq

    # get count where user worked on
    history_object = History::Object.lookup(name: 'Ticket')
    count = History.select('DISTINCT(o_id)').where(
      'histories.created_at >= ? AND histories.history_object_id = ? AND histories.created_by_id = ? AND histories.o_id IN (?)', Time.zone.now - 1.day, history_object.id, user.id, all_ticket_ids
    ).count

    total = all_ticket_ids.count
    in_process_precent = 0
    state = 'supergood'
    average_in_percent = '-'

    if total.nonzero?
      in_process_precent = ( count.to_f / (total.to_f / 100) ).round(1)
    end

    {
      used_for_average:  in_process_precent,
      average_per_agent: average_in_percent,
      state:             state,
      in_process:        count,
      percent:           in_process_precent,
      total:             total,
    }
  end

  def self.average_state(result, _user_id)

    return result if !result.key?(:used_for_average)

    if result[:total] < 1
      result[:state] = 'supergood'
      return result
    end

    in_percent = ( result[:used_for_average].to_f / (result[:average_per_agent].to_f / 100) ).round(1)
    result[:state] = if in_percent >= 90
                       'supergood'
                     elsif in_percent >= 65
                       'good'
                     elsif in_percent >= 40
                       'ok'
                     elsif in_percent >= 20
                       'bad'
                     else
                       'superbad'
                     end

    result
  end
end
