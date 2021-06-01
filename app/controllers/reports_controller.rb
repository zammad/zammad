# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class ReportsController < ApplicationController
  prepend_before_action { authentication_check && authorize! }

  # GET /api/reports/config
  def reporting_config
    if !Report.enabled?
      render json: {
        error: 'Elasticsearch need to be configured!',
      }
      return
    end
    render json: {
      config:   Report.config,
      profiles: Report::Profile.list,
    }
  end

  # GET /api/reports/generate
  def generate
    get_params = params_all
    return if !get_params

    result = {}
    get_params[:metric][:backend].each do |backend|
      condition = get_params[:profile].condition
      if backend[:condition]
        backend[:condition].merge(condition)
      else
        backend[:condition] = condition
      end
      next if !backend[:adapter]

      result[backend[:name]] = backend[:adapter].aggs(
        range_start:     get_params[:start],
        range_end:       get_params[:stop],
        interval:        get_params[:range],
        selector:        backend[:condition],
        params:          backend[:params],
        timezone:        get_params[:timezone],
        timezone_offset: get_params[:timezone_offset],
        current_user:    current_user
      )
    end

    render json: {
      data: result
    }
  end

  # GET /api/reports/sets
  def sets
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
    excel = nil
    filename = nil
    get_params[:metric][:backend].each do |backend|
      next if params[:downloadBackendSelected] != backend[:name]

      condition = get_params[:profile].condition
      if backend[:condition]
        backend[:condition].merge(condition)
      else
        backend[:condition] = condition
      end
      next if !backend[:adapter]

      result = backend[:adapter].items(
        range_start:     get_params[:start],
        range_end:       get_params[:stop],
        interval:        get_params[:range],
        selector:        backend[:condition],
        params:          backend[:params],
        sheet:           params[:sheet],
        timezone:        get_params[:timezone],
        timezone_offset: get_params[:timezone_offset],
        current_user:    current_user
      )

      result = { count: 0, ticket_ids: [] } if result.nil?

      # generate sheet
      if params[:sheet]
        excel = ExcelSheet::Ticket.new(
          title:      "#{get_params[:profile].name} (#{backend[:display]})",
          ticket_ids: result[:ticket_ids],
          timezone:   params[:timezone],
          locale:     current_user.locale,
        )
        filename = "tickets-#{get_params[:profile].name}-#{backend[:display]}.xls"
      end
      break
    end
    if excel
      send_data(
        excel.content,
        filename:    filename,
        type:        'application/vnd.ms-excel',
        disposition: 'attachment'
      )
      return
    end

    render json: result
  end

  def params_all
    profile = nil
    if !params[:profiles] && !params[:profile_id]
      raise Exceptions::UnprocessableEntity, 'No such profiles param'
    end

    if params[:profile_id]
      profile = Report::Profile.find(params[:profile_id])
    else
      params[:profiles].each do |profile_id, active|
        next if !active

        profile = Report::Profile.find(profile_id)
      end
    end
    if !profile
      raise Exceptions::UnprocessableEntity, 'No such active profile'
    end

    local_config = Report.config
    if !local_config || !local_config[:metric] || !local_config[:metric][params[:metric].to_sym]
      raise Exceptions::UnprocessableEntity, "No such metric #{params[:metric]}"
    end

    metric = local_config[:metric][params[:metric].to_sym]

    case params[:timeRange]
    when 'realtime'
      start_at = (Time.zone.now - 60.minutes)
      stop_at = Time.zone.now
      range = 'minute'
    when 'day'
      date = Date.parse("#{params[:year]}-#{params[:month]}-#{params[:day]}").to_s
      start_at = Time.zone.parse("#{date}T00:00:00Z")
      stop_at = Time.zone.parse("#{date}T23:59:59Z")
      range = 'hour'
    when 'week'
      start_week_at = Date.commercial(params[:year].to_i, params[:week].to_i)
      stop_week_at = start_week_at.end_of_week
      start_at = Time.zone.parse("#{start_week_at.year}-#{start_week_at.month}-#{start_week_at.day}T00:00:00Z")
      stop_at = Time.zone.parse("#{stop_week_at.year}-#{stop_week_at.month}-#{stop_week_at.day}T23:59:59Z")
      range = 'week'
    when 'month'
      start_at = Time.zone.parse("#{params[:year]}-#{params[:month]}-01T00:00:00Z")
      stop_at = Time.zone.parse("#{params[:year]}-#{params[:month]}-#{start_at.end_of_month.day}T23:59:59Z")
      range = 'day'
    else
      start_at = Time.zone.parse("#{params[:year]}-01-01T00:00:00Z")
      stop_at = Time.zone.parse("#{params[:year]}-12-31T23:59:59Z")
      range = 'month'
    end
    params[:timezone] ||= Setting.get('timezone_default')
    if params[:timezone].present? && params[:timeRange] != 'realtime'
      offset = stop_at.in_time_zone(params[:timezone]).utc_offset
      start_at -= offset
      stop_at -= offset
    end

    {
      profile:         profile,
      metric:          metric,
      config:          local_config,
      start:           start_at,
      stop:            stop_at,
      range:           range,
      timezone:        params[:timezone],
      timezone_offset: offset,
    }
  end

end
