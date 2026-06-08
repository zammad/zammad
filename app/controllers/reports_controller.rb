# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class ReportsController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  # GET /api/reports/config
  def reporting_config
    if !Report.enabled?
      render json: {
        error: __('Elasticsearch needs to be configured!'),
      }
      return
    end

    profiles = Report::ProfilesPolicy::Scope.new(current_user, Report::Profile).resolve.sorted
    if profiles.blank?
      render json: {
        error: __('There are currently no report profiles configured.'),
      }
      return
    end

    render json: {
      config:   Report.config,
      profiles: profiles,
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
      next if params['backends'][backend[:name]].blank?

      result[backend[:name]] = backend[:adapter].aggs(
        range_start:  get_params[:start],
        range_end:    get_params[:stop],
        interval:     get_params[:range],
        selector:     backend[:condition],
        params:       backend[:params],
        timezone:     get_params[:timezone],
        current_user: current_user
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
        error: __("Required parameter 'downloadBackendSelected' is missing."),
      }, status: :unprocessable_content
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
        range_start:  get_params[:start],
        range_end:    get_params[:stop],
        interval:     get_params[:range],
        selector:     backend[:condition],
        params:       backend[:params],
        sheet:        params[:sheet],
        timezone:     get_params[:timezone],
        current_user: current_user
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
        filename = "tickets-#{get_params[:profile].name}-#{backend[:display]}.xlsx"
      end
      break
    end
    if excel
      send_data(
        excel.content,
        filename:    filename,
        type:        ExcelSheet::CONTENT_TYPE,
        disposition: 'attachment'
      )
      return
    end

    render json: result
  end

  private

  def params_all
    if !params[:profiles] && !params[:profile_id]
      raise Exceptions::UnprocessableContent, __("Required parameter 'profile' is missing.")
    end

    if params[:profile_id]
      profile = Report::ProfilesPolicy::Scope.new(current_user, Report::Profile).resolve.find_by(id: params[:profile_id])
    else
      params[:profiles].each do |profile_id, active|
        next if !active

        profile = Report::ProfilesPolicy::Scope.new(current_user, Report::Profile).resolve.find_by(id: profile_id)
      end
    end

    if !profile
      raise Exceptions::UnprocessableContent, __('The reporting profile could not be found.')
    end

    local_config = Report.config
    if !local_config || !local_config[:metric] || !local_config[:metric][params[:metric].to_sym]
      raise Exceptions::UnprocessableContent, "Could not find metric #{params[:metric]}"
    end

    metric = local_config[:metric][params[:metric].to_sym]

    timezone = params[:timezone].presence || Setting.get('timezone_default')

    start_at, stop_at, range = Time.use_zone(timezone) do
      time_range(params[:timeRange], **params.permit(:year, :month, :day, :week).to_h.symbolize_keys)
    end

    {
      profile:  profile,
      metric:   metric,
      config:   local_config,
      start:    start_at,
      stop:     stop_at,
      range:    range,
      timezone: timezone,
    }
  end

  def time_range(time_range, year: nil, month: nil, day: nil, week: nil)
    case time_range
    when 'realtime'
      start_at = 60.minutes.ago
      stop_at = Time.zone.now
      range = 'minute'
    when 'day'
      date = Date.parse("#{year}-#{month}-#{day}")

      start_at = date.beginning_of_day
      stop_at  = date.end_of_day
      range    = 'hour'
    when 'week'
      date = Date.commercial(year.to_i, week.to_i)

      start_at = date.beginning_of_day
      stop_at  = date.end_of_week.end_of_day
      range    = 'week'
    when 'month'
      date = Date.parse("#{year}-#{month}-01")

      start_at = date.beginning_of_day
      stop_at  = date.end_of_month.end_of_day
      range    = 'day'
    else
      date = Date.parse("#{year}-01-01")

      start_at = date.beginning_of_day
      stop_at  = date.end_of_year.end_of_day
      range    = 'month'
    end

    [start_at, stop_at, range]
  end

end
