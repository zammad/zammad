# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Report::TicketReopened < Report::Base

=begin

  result = Report::TicketReopened.aggs(
    range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
    range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
    interval:    'month', # quarter, month, week, day, hour, minute, second
    selector:    selector, # ticket selector to get only a collection of tickets
    timezone:    'Europe/Berlin',
  )

returns

  [4,5,1,5,0,51,5,56,7,4]

=end

  def self.aggs(params_origin)
    params = params_origin.dup
    ticket_state_ids = ticket_ids

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

      without_merged_tickets = {
        'ticket_state.name' => {
          'operator' => 'is not',
          'value'    => 'merged'
        }
      }
      params[:selector].merge!(without_merged_tickets) # do not show merged tickets in reports
      count = history_count(
        object:    'Ticket',
        type:      'updated',
        attribute: 'state',
        id_from:   ticket_state_ids,
        id_not_to: ticket_state_ids,
        start:     params[:range_start],
        end:       params[:range_end],
        selector:  params[:selector]
      )
      result.push count
      params[:range_start] = params[:range_end]
    end
    result
  end

=begin

  result = Report::TicketReopened.items(
    range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
    range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
    selector:    selector, # ticket selector to get only a collection of tickets
    timezone:    'Europe/Berlin',
  )

returns

  {
    count: 123,
    ticket_ids: [4,5,1,5,0,51,5,56,7,4],
    assets: assets,
  }

=end

  def self.items(params)
    ticket_state_ids = ticket_ids
    result = history(
      object:    'Ticket',
      type:      'updated',
      attribute: 'state',
      id_from:   ticket_state_ids,
      id_not_to: ticket_state_ids,
      start:     params[:range_start],
      end:       params[:range_end],
      selector:  params[:selector]
    )
    return result if params[:sheet].present?

    assets = {}
    result[:ticket_ids].each do |ticket_id|
      ticket_full = Ticket.find(ticket_id)
      assets = ticket_full.assets(assets)
    end
    result[:assets] = assets
    result
  end

  def self.ticket_ids
    key = 'Report::TicketReopened::StateList'
    ticket_state_ids = Cache.read(key)
    return ticket_state_ids if ticket_state_ids

    ticket_state_types = Ticket::StateType.where(name: %w[closed merged removed])
    ticket_state_ids = []
    ticket_state_types.each do |ticket_state_type|
      ticket_state_type.states.each do |ticket_state|
        ticket_state_ids.push ticket_state.id
      end
    end
    Cache.write(key, ticket_state_ids, { expires_in: 2.days })
    ticket_state_ids
  end
end
