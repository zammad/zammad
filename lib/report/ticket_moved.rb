class Report::TicketMoved < Report::Base

=begin

  result = Report::TicketMoved.aggs(
    range_start: '2015-01-01T00:00:00Z',
    range_end:   '2015-12-31T23:59:59Z',
    interval:    'month', # quarter, month, week, day, hour, minute, second
    selector:    selector, # ticket selector to get only a collection of tickets
    params:      { type: 'in' }, # in|out
  )

returns

  [4,5,1,5,0,51,5,56,7,4]

=end

  def self.aggs(params)

    selector = params[:selector]['ticket.group_id']

    if !selector
      return [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    end

    interval = params[:interval]
    if params[:interval] == 'week'
      interval = 'day'
    end

    result = []
    if params[:interval] == 'month'
      start = Date.parse(params[:range_start])
      stop_interval = 12
    elsif params[:interval] == 'week'
      start = Date.parse(params[:range_start])
      stop_interval = 7
    elsif params[:interval] == 'day'
      start = Date.parse(params[:range_start])
      stop_interval = 31
    elsif params[:interval] == 'hour'
      start = Time.zone.parse(params[:range_start])
      stop_interval = 24
    elsif params[:interval] == 'minute'
      start = Time.zone.parse(params[:range_start])
      stop_interval = 60
    end
    (1..stop_interval).each { |_counter|
      if params[:interval] == 'month'
        stop = start.next_month
      elsif params[:interval] == 'week'
        stop = start.next_day
      elsif params[:interval] == 'day'
        stop = start.next_day
      elsif params[:interval] == 'hour'
        stop = start + 1.hour
      elsif params[:interval] == 'minute'
        stop = start + 1.minute
      end
      local_params = group_attributes(selector, params)
      local_selector = params[:selector].clone
      if params[:params][:type] == 'out'
        local_selector.delete('ticket.group_id')
      end
      defaults = {
        object: 'Ticket',
        type: 'updated',
        attribute: 'group',
        start: start,
        end: stop,
        selector: local_selector
      }
      local_params = defaults.merge(local_params)
      count = history_count(local_params)
      result.push count
      start = stop
    }
    result
  end

=begin

  result = Report::TicketMoved.items(
    range_start: '2015-01-01T00:00:00Z',
    range_end:   '2015-12-31T23:59:59Z',
    selector:    selector, # ticket selector to get only a collection of tickets
    params:      { type: 'in' }, # in|out
  )

returns

  {
    count: 123,
    ticket_ids: [4,5,1,5,0,51,5,56,7,4],
    assets: assets,
  }

=end

  def self.items(params)

    selector = params[:selector]['ticket.group_id']

    if !selector
      return {
        count: 0,
        ticket_ids: [],
      }
    end
    local_params = group_attributes(selector, params)
    local_selector = params[:selector].clone
    if params[:params][:type] == 'out'
      local_selector.delete('ticket.group_id')
    end
    defaults = {
      object: 'Ticket',
      type: 'updated',
      attribute: 'group',
      start: params[:range_start],
      end: params[:range_end],
      selector: local_selector
    }
    local_params = defaults.merge(local_params)
    result = history(local_params)
    assets = {}
    result[:ticket_ids].each { |ticket_id|
      ticket_full = Ticket.find(ticket_id)
      assets = ticket_full.assets(assets)
    }
    result[:assets] = assets
    result
  end

  def self.group_attributes(selector, params)
    if selector['operator'] == 'is'
      group_id = selector['value']
      if params[:params][:type] == 'in'
        return {
          id_not_from: group_id,
          id_to: group_id,
        }
      else
        return {
          id_from: group_id,
          id_not_to: group_id,
        }
      end
    else
      group_id = selector['value']
      if params[:params][:type] == 'in'
        return {
          id_from: group_id,
          id_not_to: group_id,
        }
      else
        return {
          id_not_from: group_id,
          id_to: group_id,
        }
      end
    end
    raise "Unknown selector params '#{selector.inspect}'"
  end
end
