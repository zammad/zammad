# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class ReportsController < ApplicationController
  before_action :authentication_check

  # GET /api/reports/config
  def config
    return if deny_if_not_role('Report')
    render json: {
      config: Report.config,
      profiles: Report::Profile.list,
    }
  end

  # GET /api/reports/generate
  def generate
    return if deny_if_not_role('Report')

    #{"metric"=>"count", "year"=>2015, "month"=>10, "week"=>43, "day"=>20, "timeSlot"=>"year", "report"=>{"metric"=>"count", "year"=>2015, "month"=>10, "week"=>43, "day"=>20, "timeSlot"=>"year"}}
    if params[:timeRange] == 'realtime'
      start = (Time.zone.now - 60.minutes).iso8601
      stop = Time.zone.now.iso8601
      created = aggs(start, stop, 'minute', 'created_at')
      closed = aggs(start, stop, 'minute', 'close_time')
    elsif params[:timeRange] == 'day'
      start = Date.parse("#{params[:year]}-#{params[:month]}-#{params[:day]}").iso8601
      start = "#{start}T00:00:00Z"
      stop = "#{start}T23:59:59Z"
      created = aggs(start, stop, 'hour', 'created_at')
      closed = aggs(start, stop, 'hour', 'close_time')
    elsif params[:timeRange] == 'week'
      start = Date.commercial(params[:year], params[:week]).iso8601
      stop = Date.parse(start).end_of_week
      created = aggs(start, stop, 'week', 'created_at')
      closed = aggs(start, stop, 'week', 'close_time')
    elsif params[:timeRange] == 'month'
      start = Date.parse("#{params[:year]}-#{params[:month]}-01}").iso8601
      stop = Date.parse(start).end_of_month
      created = aggs(start, stop, 'day', 'created_at')
      closed = aggs(start, stop, 'day', 'close_time')
    else
      start = "#{params[:year]}-01-01"
      stop = "#{params[:year]}-12-31"
      created = aggs(start, stop, 'month', 'created_at')
      closed = aggs(start, stop, 'month', 'close_time')
    end
    render json: {
      data: {
        created: created,
        closed: closed,
      }
    }
  end

  # GET /api/reports/sets
  def sets
    return if deny_if_not_role('Report')

    #{"metric"=>"count", "year"=>2015, "month"=>10, "week"=>43, "day"=>20, "timeSlot"=>"year", "report"=>{"metric"=>"count", "year"=>2015, "month"=>10, "week"=>43, "day"=>20, "timeSlot"=>"year"}}
    if params[:timeRange] == 'realtime'
      start = (Time.zone.now - 60.minutes).iso8601
      stop = Time.zone.now.iso8601
    elsif params[:timeRange] == 'day'
      start = Date.parse("#{params[:year]}-#{params[:month]}-#{params[:day]}").iso8601
      start = "#{start}T00:00:00Z"
      stop = "#{start}T23:59:59Z"
    elsif params[:timeRange] == 'week'
      start = Date.commercial(params[:year], params[:week]).iso8601
      stop = Date.parse(start).end_of_week
    elsif params[:timeRange] == 'month'
      start = Date.parse("#{params[:year]}-#{params[:month]}-01}").iso8601
      stop = Date.parse(start).end_of_month
    else
      start = "#{params[:year]}-01-01"
      stop = "#{params[:year]}-12-31"
    end

    # get data

    render json: {
      data: {
        start: start,
        stop: stop,
      }
    }
  end

  def aggs(range_start, range_end, interval, field)
    result = SearchIndexBackend.aggs(
      {
      },
      [range_start, range_end, field, interval],
      ['Ticket'],
    )
    data = []
    if interval == 'month'
      start = Date.parse(range_start)
      stop_interval = 12
    elsif interval == 'week'
      start = Date.parse(range_start)
      stop_interval = 7
    elsif interval == 'day'
      start = Date.parse(range_start)
      stop_interval = 31
    elsif interval == 'hour'
      start = Time.zone.parse(range_start)
      stop_interval = 24
    elsif interval == 'minute'
      start = Time.zone.parse(range_start)
      stop_interval = 60
    end
    (1..stop_interval).each {|counter|
      match = false
      result['aggregations']['time_buckets']['buckets'].each {|item|
        if interval == 'minute'
          start_string = start.iso8601.sub(/:\d\d.+?$/, '')
        else
          start_string = start.iso8601.sub(/:\d\d:\d\d.+?$/, '')
        end
        next if !item['doc_count']
        next if item['key_as_string'] !~ /#{start_string}/
        match = true
        data.push [counter, item['doc_count']]
        if interval == 'month'
          start = start.next_month
        elsif interval == 'week'
          start = start.next_week
        elsif interval == 'day'
          start = start.next_day
        elsif interval == 'hour'
          start = start + 1.hour
        elsif interval == 'minute'
          start = start + 1.minute
        end
      }
      next if match
      data.push [counter, 0]
      if interval == 'month'
        start = start.next_month
      elsif interval == 'week'
        start = start.next_week
      elsif interval == 'day'
        start = start + 1.day
      elsif interval == 'hour'
        start = start + 1.hour
      elsif interval == 'minute'
        start = start + 1.minute
      end
    }
    data
  end
end
