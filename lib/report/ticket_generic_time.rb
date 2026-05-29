# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Report::TicketGenericTime < Report::BaseElasticSearch

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
    params = duplicate_preserving_current_user(params_origin)
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

    selector = params[:selector].clone
    if params[:params].present? && params[:params][:selector].present?
      selector = selector.merge(params[:params][:selector])
    end
    selector.merge!(without_merged_tickets_selector) # do not show merged tickets in reports

    result_es = SearchIndexBackend.selectors('Ticket', selector, { current_user: params[:current_user] }, aggs_interval)

    if !result_es
      raise "Invalid es result #{result_es.inspect}"
    end

    buckets = result_es.dig('aggregations', 'time_buckets', 'buckets')

    if !buckets
      raise "Invalid es result, no aggregations.time_buckets.buckets #{result_es.inspect}"
    end

    buckets.pluck('doc_count')
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

    selector = params[:selector].clone
    if params[:params] && params[:params][:selector]
      selector = selector.merge(params[:params][:selector])
    end
    selector.merge!(without_merged_tickets_selector) # do not show merged tickets in reports

    result = SearchIndexBackend.selectors('Ticket', selector, { current_user: params[:current_user], limit: limit }, aggs_interval)
    result[:ticket_ids] = result.delete(:object_ids)
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
