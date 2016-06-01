# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

require 'tempfile'

class ReportsController < ApplicationController
  before_action :authentication_check

  # GET /api/reports/config
  def reporting_config
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
        sheet:       params[:sheet],
      )

      # generate sheet
      next if !params[:sheet]
      content = sheet(get_params[:profile], backend[:display], result)
      send_data(
        content,
        filename: "tickets-#{get_params[:profile].name}-#{backend[:display]}.xls",
        type: 'application/vnd.ms-excel',
        disposition: 'attachment'
      )
    }
    return if params[:sheet]

    render json: result
  end

  def params_all
    profile = nil
    if !params[:profiles] && !params[:profile_id]
      render json: {
        error: 'No such profiles param',
      }, status: :unprocessable_entity
      return
    end
    if params[:profile_id]
      profile = Report::Profile.find(params[:profile_id])
    else
      params[:profiles].each {|profile_id, active|
        next if !active
        profile = Report::Profile.find(profile_id)
      }
    end
    if !profile
      render json: {
        error: 'No such active profile',
      }, status: :unprocessable_entity
      return
    end

    local_config = Report.config
    if !local_config || !local_config[:metric] || !local_config[:metric][params[:metric].to_sym]
      render json: {
        error: "No such metric #{params[:metric]}"
      }, status: :unprocessable_entity
      return
    end
    metric = local_config[:metric][params[:metric].to_sym]

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
      start     = "#{params[:year]}-01-01"
      stop_date = Date.parse(day_start).end_of_month
      stop      = "#{stop_date.year}-#{stop_date.month}-#{stop_date.day}"
      range     = 'month'
    end
    {
      profile: profile,
      metric: metric,
      config: local_config,
      start: start,
      stop: stop,
      range: range,
    }
  end

  def sheet(profile, title, result)

    # Create a new Excel workbook
    temp_file = Tempfile.new('time_tracking.xls')
    workbook = WriteExcel.new(temp_file)

    # Add a worksheet
    worksheet = workbook.add_worksheet
    worksheet.set_column(0, 0, 10)
    worksheet.set_column(1, 1, 34)
    worksheet.set_column(2, 2, 10)
    worksheet.set_column(3, 3, 10)
    worksheet.set_column(4, 7, 20)

    #  Add and define a format
    format = workbook.add_format  # Add a format
    format.set_bold
    format.set_size(14)
    format.set_color('black')
    worksheet.set_row(0, 0, 6)

    # Write a formatted and unformatted string, row and column notation.
    worksheet.write(0, 0, "Tickets: #{profile.name} (#{title})", format)

    format_header = workbook.add_format  # Add a format
    format_header.set_italic
    format_header.set_bg_color('gray')
    format_header.set_color('white')
    worksheet.write(2, 0, '#', format_header )
    worksheet.write(2, 1, 'Title', format_header )
    worksheet.write(2, 2, 'State', format_header )
    worksheet.write(2, 3, 'Priority', format_header )
    worksheet.write(2, 4, 'Customer', format_header )
    worksheet.write(2, 5, 'Created at', format_header )
    worksheet.write(2, 6, 'Updated at', format_header )
    worksheet.write(2, 7, 'Closed at', format_header )

    row = 2
    result[:ticket_ids].each {|ticket_id|
      ticket = Ticket.lookup(id: ticket_id)
      row += 1
      worksheet.write(row, 0, ticket.number )
      worksheet.write(row, 1, ticket.title)
      worksheet.write(row, 2, ticket.state.name)
      worksheet.write(row, 3, ticket.priority.name)
      worksheet.write(row, 4, ticket.customer.fullname)
      worksheet.write(row, 5, ticket.created_at)
      worksheet.write(row, 6, ticket.updated_at)
      worksheet.write(row, 7, ticket.close_time)
    }

    workbook.close

    # read file again
    file = File.new(temp_file, 'r')
    contents = file.read
    file.close
    contents
  end

end
