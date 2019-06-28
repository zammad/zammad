class Report::ArticleByTypeSender < Report::Base

=begin

  result = Report::ArticleByTypeSender.aggs(
    range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
    range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
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

  def self.aggs(params_origin)
    params = params_origin.dup

    result = []
    if params[:interval] == 'month'
      stop_interval = 12
    elsif params[:interval] == 'week'
      stop_interval = 7
    elsif params[:interval] == 'day'
      stop_interval = 31
    elsif params[:interval] == 'hour'
      stop_interval = 24
    elsif params[:interval] == 'minute'
      stop_interval = 60
    end
    (1..stop_interval).each do |_counter|
      if params[:interval] == 'month'
        params[:range_end] = params[:range_start].next_month
      elsif params[:interval] == 'week'
        params[:range_end] = params[:range_start].next_day
      elsif params[:interval] == 'day'
        params[:range_end] = params[:range_start].next_day
      elsif params[:interval] == 'hour'
        params[:range_end] = params[:range_start] + 1.hour
      elsif params[:interval] == 'minute'
        params[:range_end] = params[:range_start] + 1.minute
      end
      query, bind_params, tables = Ticket.selector2sql(params[:selector])
      sender = Ticket::Article::Sender.lookup(name: params[:params][:sender])
      type   = Ticket::Article::Type.lookup(name: params[:params][:type])
      count = Ticket::Article.joins('INNER JOIN tickets ON tickets.id = ticket_articles.ticket_id')
                             .where(query, *bind_params).joins(tables)
                             .where(
                               'ticket_articles.created_at >= ? AND ticket_articles.created_at <= ? AND ticket_articles.type_id = ? AND ticket_articles.sender_id = ?',
                               params[:range_start],
                               params[:range_end],
                               type.id,
                               sender.id,
                             ).count
      result.push count
      params[:range_start] = params[:range_end]
    end
    result
  end

=begin

  result = Report::ArticleByTypeSender.items(
    range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
    range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
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
