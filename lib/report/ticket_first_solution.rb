# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Report::TicketFirstSolution

=begin

  result = Report::TicketFirstSolution.aggs(
    range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
    range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
    interval:    'month', # quarter, month, week, day, hour, minute, second
    selector:    selector, # ticket selector to get only a collection of tickets
  )

returns

  [4,5,1,5,0,51,5,56,7,4]

=end

  def self.aggs(params_origin)
    params = params_origin.dup

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
      params[:selector].merge!(without_merged_tickets)
      query, bind_params, tables = Ticket.selector2sql(params[:selector])
      ticket_list = Ticket.select('tickets.id, tickets.close_at, tickets.created_at').where(
        'tickets.close_at IS NOT NULL AND tickets.close_at >= ? AND tickets.close_at < ?',
        params[:range_start],
        params[:range_end],
      ).where(query, *bind_params).joins(tables)
      count = 0
      ticket_list.each do |ticket|
        closed_at  = ticket.close_at
        created_at = ticket.created_at
        if (closed_at - (60 * 15) ) < created_at
          count += 1
        end
      end
      result.push count
      params[:range_start] = params[:range_end]
    end
    result
  end

=begin

  result = Report::TicketFirstSolution.items(
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
    without_merged_tickets = {
      'ticket_state.name' => {
        'operator' => 'is not',
        'value'    => 'merged'
      }
    }

    selector = params[:selector].merge!(without_merged_tickets)
    query, bind_params, tables = Ticket.selector2sql(selector)
    ticket_list = Ticket.select('tickets.id, tickets.close_at, tickets.created_at').where(
      'tickets.close_at IS NOT NULL AND tickets.close_at >= ? AND tickets.close_at < ?',
      params[:range_start],
      params[:range_end],
    ).where(query, *bind_params).joins(tables).order(close_at: :asc)
    count = 0
    assets = {}
    ticket_ids = []
    ticket_list.each do |ticket|
      closed_at  = ticket.close_at
      created_at = ticket.created_at
      if (closed_at - (60 * 15) ) < created_at
        count += 1
        ticket_ids.push ticket.id
      end
      ticket_full = Ticket.find(ticket.id)
      assets = ticket_full.assets(assets)
    end
    {
      count:      count,
      ticket_ids: ticket_ids,
      assets:     assets,
    }
  end

end
