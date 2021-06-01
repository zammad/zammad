# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Report::TicketGenericTime

=begin

  result = Report::TicketGenericTime.aggs(
    range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
    range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
    interval:    'month', # year, quarter, month, week, day, hour, minute, second
    selector:    selector, # ticket selector to get only a collection of tickets
    params:      { field: 'created_at', selector: selector_sub },
    timezone:    'Europe/Berlin',
  )

returns

  [4,5,1,5,0,51,5,56,7,4]

=end

  def self.aggs(params_origin)
    params = params_origin.dup
    interval_es = params[:interval]
    if params[:interval] == 'week'
      interval_es = 'day'
    end

    aggs_interval = {
      from:     params[:range_start].iso8601,
      to:       params[:range_end].iso8601,
      interval: interval_es, # year, quarter, month, week, day, hour, minute, second
      field:    params[:params][:field],
      timezone: params[:timezone],
    }

    without_merged_tickets = {
      'state.name' => {
        'operator' => 'is not',
        'value'    => 'merged'
      }
    }

    selector = params[:selector].clone
    if params[:params].present? && params[:params][:selector].present?
      selector = selector.merge(params[:params][:selector])
    end
    selector.merge!(without_merged_tickets) # do not show merged tickets in reports

    result_es = SearchIndexBackend.selectors('Ticket', selector, { current_user: params[:current_user] }, aggs_interval)
    case params[:interval]
    when 'month'
      stop_interval = 12
    when 'week'
      stop_interval = 7
    when 'day'
      stop_interval = ((params[:range_end] - params[:range_start]) / 86_400).to_i + 1
    when 'hour'
      stop_interval = 24
    when 'minute'
      stop_interval = 60
    end
    result = []
    (1..stop_interval).each do |_counter|
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

      result_es['aggregations']['time_buckets']['buckets'].each do |item|
        key_as_string = Time.zone.parse(item['key_as_string'])
        next if !item['doc_count']
        next if item['doc_count'].zero?

        # only compare date - in certain cases elasticsearch timezone offset will not match
        replace = ':\d\dZ$'
        case params[:interval]
        when 'month'
          replace = '\d\dT\d\d:\d\d:\d\dZ$'
        when 'day', 'week'
          replace = '\d\d:\d\d:\d\dZ$'
        end

        next if key_as_string.iso8601.sub(%r{#{replace}}, '') != params[:range_start].iso8601.sub(%r{#{replace}}, '')
        next if match

        match = true
        result.push item['doc_count']
        case params[:interval]
        when 'month'
          params[:range_start] = params[:range_start].next_month
        when 'week', 'day'
          params[:range_start] = params[:range_start].next_day
        when 'hour'
          params[:range_start] = params[:range_start] + 1.hour
        when 'minute'
          params[:range_start] = params[:range_start] + 1.minute
        end
      end
      next if match

      result.push 0
      case params[:interval]
      when 'month'
        params[:range_start] = params[:range_start].next_month
      when 'week'
        params[:range_start] = params[:range_start].next_day
      when 'day'
        params[:range_start] = params[:range_start] + 1.day
      when 'hour'
        params[:range_start] = params[:range_start] + 1.hour
      when 'minute'
        params[:range_start] = params[:range_start] + 1.minute
      end
    end
    result
  end

=begin

  result = Report::TicketGenericTime.items(
    range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
    range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
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
      from:  params[:range_start].iso8601,
      to:    params[:range_end].iso8601,
      field: params[:params][:field],
    }

    limit = 6000
    if params[:sheet].blank?
      limit = 100
    end

    without_merged_tickets = {
      'state.name' => {
        'operator' => 'is not',
        'value'    => 'merged'
      }
    }

    selector = params[:selector].clone
    if params[:params] && params[:params][:selector]
      selector = selector.merge(params[:params][:selector])
    end
    selector.merge!(without_merged_tickets) # do not show merged tickets in reports

    result = SearchIndexBackend.selectors('Ticket', selector, { current_user: params[:current_user], limit: limit }, aggs_interval)
    return result if params[:sheet].present?

    assets = {}
    result[:ticket_ids].each do |ticket_id|
      suppress(ActiveRecord::RecordNotFound) do
        ticket_full = Ticket.find(ticket_id)
        assets = ticket_full.assets(assets)
      end
    end
    result[:assets] = assets
    result
  end

end
