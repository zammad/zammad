# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Stats::TicketLoadMeasure

  def self.generate(user)

    open_state_ids = Ticket::State.by_category(:open).pluck(:id)

    # owned tickets
    count = Ticket.where(owner_id: user.id, state_id: open_state_ids).count

    # get total open
    total = Ticket.where(group_id: user.group_ids_access('full'), state_id: open_state_ids).count

    average = '-'
    state = 'good'
    load_measure_precent = 0

    if count > total
      total = count
    end

    if total.nonzero?
      load_measure_precent = ( count.to_f / (total.to_f / 100) ).round(1)
    end
    {
      used_for_average:  load_measure_precent,
      average_per_agent: average,
      percent:           load_measure_precent,
      state:             state,
      own:               count,
      total:             total,
    }
  end

  def self.average_state(result, _user_id)

    return result if !result.key?(:used_for_average)

    if result[:total] < 1 || result[:average_per_agent].to_d == 0.0.to_d
      result[:state] = 'supergood'
      return result
    end

    in_percent = ( result[:used_for_average].to_f / (result[:average_per_agent].to_f / 100) ).round(1)
    result[:average_per_agent_in_percent] = in_percent
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

    # convert result[:used_for_average] in percent to related total
    result[:average_per_agent] = ( (result[:total].to_f / 100) * result[:average_per_agent] ).round(1)

    result
  end

end
