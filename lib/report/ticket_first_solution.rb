class Report::TicketFirstSolution

=begin

  result = Report::TicketFirstSolution.aggs(
    range_start: '2015-01-01T00:00:00Z',
    range_end:   '2015-12-31T23:59:59Z',
    interval:    'month', # quarter, month, week, day, hour, minute, second
    selector:    selector, # ticket selector to get only a collection of tickets
  )

returns

  [4,5,1,5,0,51,5,56,7,4]

=end

  def self.aggs(params)
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
      query, bind_params, tables = Ticket.selector2sql(params[:selector])
      ticket_list = Ticket.select('tickets.id, tickets.close_at, tickets.created_at').where(
        'tickets.close_at IS NOT NULL AND tickets.close_at >= ? AND tickets.close_at < ?',
        start,
        stop,
      ).where(query, *bind_params).joins(tables)
      count = 0
      ticket_list.each { |ticket|
        closed_at  = ticket.close_at
        created_at = ticket.created_at
        if (closed_at - (60 * 15) ) < created_at
          count += 1
        end
      }
      result.push count
      start = stop
    }
    result
  end

=begin

  result = Report::TicketFirstSolution.items(
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
    query, bind_params, tables = Ticket.selector2sql(params[:selector])
    ticket_list = Ticket.select('tickets.id, tickets.close_at, tickets.created_at').where(
      'tickets.close_at IS NOT NULL AND tickets.close_at >= ? AND tickets.close_at < ?',
      params[:range_start],
      params[:range_end],
    ).where(query, *bind_params).joins(tables).order(close_at: :asc)
    count = 0
    assets = {}
    ticket_ids = []
    ticket_list.each { |ticket|
      closed_at  = ticket.close_at
      created_at = ticket.created_at
      if (closed_at - (60 * 15) ) < created_at
        count += 1
        ticket_ids.push ticket.id
      end
      ticket_full = Ticket.find(ticket.id)
      assets = ticket_full.assets(assets)
    }
    {
      count: count,
      ticket_ids: ticket_ids,
      assets: assets,
    }
  end

end
