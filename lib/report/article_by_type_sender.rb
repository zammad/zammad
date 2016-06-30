class Report::ArticleByTypeSender < Report::Base

=begin

  result = Report::ArticleByTypeSender.aggs(
    range_start: '2015-01-01T00:00:00Z',
    range_end:   '2015-12-31T23:59:59Z',
    interval:    'month', # quarter, month, week, day, hour, minute, second
    selector:    selector, # ticket selector to get only a collection of tickets
    params: {
      type: 'phone',
      sender: 'Customer',
    }
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
      sender = Ticket::Article::Sender.lookup(name: params[:params][:sender])
      type   = Ticket::Article::Type.lookup(name: params[:params][:type])
      count = Ticket::Article.joins('INNER JOIN tickets ON tickets.id = ticket_articles.ticket_id')
                             .where(query, *bind_params).joins(tables)
                             .where(
                               'ticket_articles.created_at >= ? AND ticket_articles.created_at <= ? AND ticket_articles.type_id = ? AND ticket_articles.sender_id = ?',
                               start,
                               stop,
                               type.id,
                               sender.id,
                             ).count
      result.push count
      start = stop
    }
    result
  end

=begin

  result = Report::ArticleByTypeSender.items(
    range_start: '2015-01-01T00:00:00Z',
    range_end:   '2015-12-31T23:59:59Z',
    selector:    selector, # ticket selector to get only a collection of tickets
    selector:    selector, # ticket selector to get only a collection of tickets
    params: {
      type: 'phone',
      sender: 'Customer',
    }
  )

returns

  {}

=end

  def self.items(_params)
    {}
  end
end
