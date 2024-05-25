# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Report::TicketMerged < Report::Base

  # Returns amount of merged tickets in a given time range
  # sliced by given time interval.
  #
  # @example
  #
  # result = Report::TicketMerged.aggs(
  #   range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
  #   range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
  #   interval:    'month', # month, week, day, hour, minute, second
  #   selector:    selector, # ticket selector to get only a collection of tickets
  #   timezone:    'Europe/Berlin',
  # )
  # #=> [4,5,1,5,0,51,5,56,7,4]
  #
  # @return [Array<Integer>]
  def self.aggs(params_origin)
    params = params_origin.deep_dup

    Array.new(interval_length(params)) do |_counter|
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

      count = history_count(query_params(params))

      params[:range_start] = params[:range_end]

      count
    end
  end

  # Returns merged tickets in a given time range matching the selector
  #
  # @example
  #
  # result = Report::TicketMerged.items(
  #   range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
  #   range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
  #   selector:    selector, # ticket selector to get only a collection of tickets
  # )
  #
  # #=> {
  #   count: 123,
  #   ticket_ids: [4,5,1,5,0,51,5,56,7,4],
  #   assets: assets,
  # }
  #
  # @return [Hash]
  def self.items(params)
    result = history(query_params(params))

    if params[:sheet].blank?
      result[:assets] = ApplicationModel::CanAssets
        .reduce(Ticket.where(id: result[:ticket_ids]), {})
    end

    result
  end

  def self.query_params(params)
    {
      object:    'Ticket',
      type:      'updated',
      attribute: 'state',
      start:     params[:range_start],
      end:       params[:range_end],
      selector:  params[:selector],
      id_to:     Ticket::State.lookup(name: 'merged').id,
    }
  end
end
