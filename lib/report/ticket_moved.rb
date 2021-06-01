# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Report::TicketMoved < Report::Base

=begin

  result = Report::TicketMoved.aggs(
    range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
    range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
    interval:    'month', # quarter, month, week, day, hour, minute, second
    selector:    selector, # ticket selector to get only a collection of tickets
    params:      { type: 'in' }, # in|out
    timezone:    'Europe/Berlin',
  )

returns

  [4,5,1,5,0,51,5,56,7,4]

=end

  def self.aggs(params_origin)
    params = params_origin.dup

    selector = params[:selector]['ticket.group_id']

    if !selector
      return [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    end

    result = []
    case params[:interval]
    when 'month'
      stop_interval = 12
    when 'week'
      stop_interval = 7
    when 'day'
      stop_interval = 31
    when 'hour'
      stop_interval = 24
    when 'minute'
      stop_interval = 60
    end
    (1..stop_interval).each do |_counter|
      case params[:interval]
      when 'month'
        params[:range_end] = params[:range_start].next_month
      when 'week', 'day'
        params[:range_end] = params[:range_start].next_day
      when 'hour'
        params[:range_end] = params[:range_start] + 1.hour
      when 'minute'
        params[:range_end] = params[:range_start] + 1.minute
      end
      local_params = group_attributes(selector, params)
      local_selector = params[:selector].clone
      without_merged_tickets = {
        'ticket_state.name' => {
          'operator' => 'is not',
          'value'    => 'merged'
        }
      }
      local_selector.merge!(without_merged_tickets) # do not show merged tickets in reports
      if params[:params][:type] == 'out'
        local_selector.delete('ticket.group_id')
      end
      defaults = {
        object:    'Ticket',
        type:      'updated',
        attribute: 'group',
        start:     params[:range_start],
        end:       params[:range_end],
        selector:  local_selector
      }
      local_params = defaults.merge(local_params)
      count = history_count(local_params)
      result.push count
      params[:range_start] = params[:range_end]
    end
    result
  end

=begin

  result = Report::TicketMoved.items(
    range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
    range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
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
        count:      0,
        ticket_ids: [],
      }
    end
    local_params = group_attributes(selector, params)
    without_merged_tickets = {
      'ticket_state.name' => {
        'operator' => 'is not',
        'value'    => 'merged'
      }
    }
    local_selector = params[:selector].merge!(without_merged_tickets) # do not show merged tickets in reports
    if params[:params][:type] == 'out'
      local_selector.delete('ticket.group_id')
    end
    defaults = {
      object:    'Ticket',
      type:      'updated',
      attribute: 'group',
      start:     params[:range_start],
      end:       params[:range_end],
      selector:  local_selector
    }
    local_params = defaults.merge(local_params)
    result = history(local_params)
    return result if params[:sheet].present?

    assets = {}
    result[:ticket_ids].each do |ticket_id|
      ticket_full = Ticket.find(ticket_id)
      assets = ticket_full.assets(assets)
    end
    result[:assets] = assets
    result
  end

  def self.group_attributes(selector, params)
    group_id = selector['value']
    case selector['operator']
    when 'is'
      if params[:params][:type] == 'in'
        return {
          id_not_from: group_id,
          id_to:       group_id,
        }
      else
        return {
          id_from:   group_id,
          id_not_to: group_id,
        }
      end
    when 'is not'
      if params[:params][:type] == 'in'
        return {
          id_from:   group_id,
          id_not_to: group_id,
        }
      else
        return {
          id_not_from: group_id,
          id_to:       group_id,
        }
      end
    end
    raise "Unknown selector params '#{selector.inspect}'"
  end
end
