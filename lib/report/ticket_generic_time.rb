class Report::TicketGenericTime

=begin

  result = Report::TicketGenericTime.aggs(
    range_start: '2015-01-01T00:00:00Z',
    range_end:   '2015-12-31T23:59:59Z',
    interval:    'month', # year, quarter, month, week, day, hour, minute, second
    selector:    selector, # ticket selector to get only a collection of tickets
    params:      { field: 'created_at', selector: selector_sub },
  )

returns

  [4,5,1,5,0,51,5,56,7,4]

=end

  def self.aggs(params)
    interval_es = params[:interval]
    if params[:interval] == 'week'
      interval_es = 'day'
    end

    aggs_interval = {
      from: params[:range_start],
      to: params[:range_end],
      interval: interval_es, # year, quarter, month, week, day, hour, minute, second
      field: params[:params][:field],
    }

    selector = params[:selector].clone
    if params[:params] && params[:params][:selector]
      selector = selector.merge(params[:params][:selector])
    end

    result_es = SearchIndexBackend.selectors(['Ticket'], selector, nil, nil, aggs_interval)

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
    result = []
    (1..stop_interval).each { |_counter|
      match = false
      if !result_es
        raise "Invalid es result #{result_es.inspect}"
      end
      if !result_es['aggregations']
        raise "Invalid es result, no aggregations #{result_es.inspect}"
      end
      if !result_es['aggregations']['time_buckets']
        raise "Invalid es result, no time_buckets #{result_es.inspect}"
      end
      if !result_es['aggregations']['time_buckets']['buckets']
        raise "Invalid es result, no buckets #{result_es.inspect}"
      end
      result_es['aggregations']['time_buckets']['buckets'].each { |item|
        if params[:interval] == 'minute'
          item['key_as_string'] = item['key_as_string'].sub(/:\d\d.\d\d\dZ$/, '')
          start_string = start.iso8601.sub(/:\d\dZ$/, '')
        else
          start_string = start.iso8601.sub(/:\d\d:\d\d.+?$/, '')
        end
        next if !item['doc_count']
        next if item['key_as_string'] !~ /#{start_string}/
        next if match
        match = true
        result.push item['doc_count']
        if params[:interval] == 'month'
          start = start.next_month
        elsif params[:interval] == 'week'
          start = start.next_day
        elsif params[:interval] == 'day'
          start = start.next_day
        elsif params[:interval] == 'hour'
          start = start + 1.hour
        elsif params[:interval] == 'minute'
          start = start + 1.minute
        end
      }
      next if match
      result.push 0
      if params[:interval] == 'month'
        start = start.next_month
      elsif params[:interval] == 'week'
        start = start.next_day
      elsif params[:interval] == 'day'
        start = start + 1.day
      elsif params[:interval] == 'hour'
        start = start + 1.hour
      elsif params[:interval] == 'minute'
        start = start + 1.minute
      end
    }
    result
  end

=begin

  result = Report::TicketGenericTime.items(
    range_start: '2015-01-01T00:00:00Z',
    range_end:   '2015-12-31T23:59:59Z',
    selector:    selector, # ticket selector to get only a collection of tickets
    params:      { field: 'created_at' },
  )

returns

  {
    count: 123,
    ticket_ids: [4,5,1,5,0,51,5,56,7,4],
    assets: assets,
  }

=end

  def self.items(params)

    aggs_interval = {
      from: params[:range_start],
      to: params[:range_end],
      field: params[:params][:field],
    }

    limit = 1000
    if !params[:sheet]
      limit = 100
    end

    selector = params[:selector].clone
    if params[:params] && params[:params][:selector]
      selector = selector.merge(params[:params][:selector])
    end

    result = SearchIndexBackend.selectors(['Ticket'], selector, limit, nil, aggs_interval)
    assets = {}
    result[:ticket_ids].each { |ticket_id|
      ticket_full = Ticket.find(ticket_id)
      assets = ticket_full.assets(assets)
    }
    result[:assets] = assets
    result
  end

end
