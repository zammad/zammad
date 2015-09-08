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

    if count > total
      total = count
    end

    if total != 0
      load_measure_precent = ( count.to_f / (total.to_f/100) ).round(1)
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

  def self.average_state(result, _user_id)

    return result if !result.key?(:used_for_average)

    if result[:total] < 1
      result[:state] = 'supergood'
      return result
    end

    in_percent = ( result[:used_for_average].to_f / (result[:average_per_agent].to_f/100) ).round(1)
    result[:average_per_agent_in_percent] = in_percent
    if in_percent >= 90
      result[:state] = 'supergood'
    elsif in_percent >= 65
      result[:state] = 'good'
    elsif in_percent >= 40
      result[:state] = 'ok'
    elsif in_percent >= 20
      result[:state] = 'bad'
    else
      result[:state] = 'superbad'
    end

    # convert result[:used_for_average] in percent to related total
    result[:average_per_agent] = ( (result[:total].to_f/100) * result[:used_for_average] ).round(1)

    result
  end

end
