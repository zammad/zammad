# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

class Stats::TicketLoadMeasure

  def self.generate(user)

    # owned tickets
    count = Ticket.where(owner_id: user.id).count

    # get total open
    total = Ticket.where(group_id: user.groups.map(&:id), state_id: Ticket::State.by_category('open').map(&:id) ).count

    average = '-'
    state = 'good'
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
    load_measure_precent = (count * 1000) / ((total * 1000) / 100)

    {
      average: average,
      percent: load_measure_precent,
      state: state,
      own: count,
      total: total,
    }
  end

end
