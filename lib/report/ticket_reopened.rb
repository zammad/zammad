class Report::TicketReopened < Report::Base

=begin

  result = Report::TicketReopened.aggs(
    range_start: '2015-01-01T00:00:00Z',
    range_end:   '2015-12-31T23:59:59Z',
    interval:    'month', # quarter, month, week, day, hour, minute, second
    selector:    selector, # ticket selector to get only a collection of tickets
  )

returns

  [4,5,1,5,0,51,5,56,7,4]

=end

  def self.aggs(params)
    ticket_state_ids = ticket_ids

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
      count = history_count(
        object: 'Ticket',
        type: 'updated',
        attribute: 'state',
        id_from: ticket_state_ids,
        id_not_to: ticket_state_ids,
        start: start,
        end: stop,
        selector: params[:selector]
      )
      result.push count
      start = stop
    }
    result
  end

=begin

  result = Report::TicketReopened.items(
    range_start: '2015-01-01T00:00:00Z',
    range_end:   '2015-12-31T23:59:59Z',
    selector:    selector, # ticket selector to get only a collection of tickets
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
      object: 'Ticket',
      type: 'updated',
      attribute: 'state',
      id_from: ticket_state_ids,
      id_not_to: ticket_state_ids,
      start: params[:range_start],
      end: params[:range_end],
      selector: params[:selector]
    )
    assets = {}
    result[:ticket_ids].each { |ticket_id|
      ticket_full = Ticket.find(ticket_id)
      assets = ticket_full.assets(assets)
    }
    result[:assets] = assets
    result
  end

  def self.ticket_ids
    key = 'Report::TicketReopened::StateList'
    ticket_state_ids = Cache.get( key )
    return ticket_state_ids if ticket_state_ids
    ticket_state_types = Ticket::StateType.where( name: %w(closed merged removed) )
    ticket_state_ids = []
    ticket_state_types.each { |ticket_state_type|
      ticket_state_type.states.each { |ticket_state|
        ticket_state_ids.push ticket_state.id
      }
    }
    Cache.write( key, ticket_state_ids, { expires_in: 2.days } )
    ticket_state_ids
  end
end
