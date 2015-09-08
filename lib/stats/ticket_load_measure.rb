# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

class Stats::TicketLoadMeasure

  def self.generate(user)

    open_state_ids = Ticket::State.by_category('work_on_all').map(&:id)

    # owned tickets
    count = Ticket.where(owner_id: user.id, state_id: open_state_ids).count

    # get total open
    total = Ticket.where(group_id: user.groups.map(&:id), state_id: open_state_ids).count

    average = '-'
    state = 'good'
    load_measure_precent = 0
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

    if count > total
      total = count
    end

    if total != 0
      load_measure_precent = (count * 1000) / ((total * 1000) / 100)
    end
    {
      used_for_average: load_measure_precent,
      average_per_agent: average,
      percent: load_measure_precent,
      state: state,
      own: count,
      total: total,
    }
  end

end
