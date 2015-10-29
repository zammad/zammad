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

    get_params = params_all
    return if !get_params

    result = {}
    get_params[:metric][:backend].each {|backend|
      condition = get_params[:profile].condition
      if backend[:condition]
        backend[:condition].merge(condition)
      else
        backend[:condition] = condition
      end
      next if !backend[:adapter]
      result[backend[:name]] = backend[:adapter].aggs(
        range_start: get_params[:start],
        range_end:   get_params[:stop],
        interval:    get_params[:range],
        selector:    backend[:condition],
        params:      backend[:params],
      )
    }

    #created = aggs(start, stop, range, 'created_at', profile.condition)
    #closed = aggs(start, stop, range, 'close_time', profile.condition)
    #first_solution =
    #reopend = backend(start, stop, range, Report::TicketReopened, profile.condition)

    # add backlog
    #backlogs = []
    #position = -1
    #created.each {|_not_used|
    # position += 1
    #  diff = created[position][1] - closed[position][1]
    #  backlog = [position+1, diff]
    #  backlogs.push backlog
    #}

    render json: {
      data: result
    }
  end

  # GET /api/reports/sets
  def sets
    return if deny_if_not_role('Report')

    get_params = params_all
    return if !get_params

    if !params[:downloadBackendSelected]
      render json: {
        error: 'No such downloadBackendSelected param',
      }, status: :unprocessable_entity
      return
    end

    # get data
    result = {}
    get_params[:metric][:backend].each {|backend|
      next if params[:downloadBackendSelected] != backend[:name]
      condition = get_params[:profile].condition
      if backend[:condition]
        backend[:condition].merge(condition)
      else
        backend[:condition] = condition
      end
      next if !backend[:adapter]
      result = backend[:adapter].items(
        range_start: get_params[:start],
        range_end:   get_params[:stop],
        interval:    get_params[:range],
        selector:    backend[:condition],
        params:      backend[:params],
      )
    }
    render json: result
  end

  def params_all
    profile = nil
    if !params[:profiles]
      render json: {
        error: 'No such profiles param',
      }, status: :unprocessable_entity
      return
    end
    params[:profiles].each {|profile_id, active|
      next if !active
      profile = Report::Profile.find(profile_id)
    }
    if !profile
      render json: {
        error: 'No such active profile',
      }, status: :unprocessable_entity
      return
    end

    config = Report.config
    if !config || !config[:metric] || !config[:metric][params[:metric].to_sym]
      render json: {
        error: "No such metric #{params[:metric]}"
      }, status: :unprocessable_entity
      return
    end
    metric = config[:metric][params[:metric].to_sym]

    #{"metric"=>"count", "year"=>2015, "month"=>10, "week"=>43, "day"=>20, "timeSlot"=>"year", "report"=>{"metric"=>"count", "year"=>2015, "month"=>10, "week"=>43, "day"=>20, "timeSlot"=>"year"}}
    if params[:timeRange] == 'realtime'
      start = (Time.zone.now - 60.minutes).iso8601
      stop = Time.zone.now.iso8601
      range = 'minute'
    elsif params[:timeRange] == 'day'
      date = Date.parse("#{params[:year]}-#{params[:month]}-#{params[:day]}").to_s
      start = "#{date}T00:00:00Z"
      stop = "#{date}T23:59:59Z"
      range = 'hour'
    elsif params[:timeRange] == 'week'
      start = Date.commercial(params[:year], params[:week]).iso8601
      stop = Date.parse(start).end_of_week
      range = 'week'
    elsif params[:timeRange] == 'month'
      start = Date.parse("#{params[:year]}-#{params[:month]}-01}").iso8601
      stop = Date.parse(start).end_of_month
      range = 'day'
    else
      start = "#{params[:year]}-01-01"
      stop = "#{params[:year]}-12-31"
      range = 'month'
    end
    {
      profile: profile,
      metric: metric,
      config: config,
      start: start,
      stop: stop,
      range: range,
    }
  end

end
