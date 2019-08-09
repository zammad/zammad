# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
class ReportsController < ApplicationController
  prepend_before_action { authentication_check(permission: 'report') }

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
    content = nil
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
      )

      result = { count: 0, ticket_ids: [] } if result.nil?

      # generate sheet
      if params[:sheet]
        content = sheet(get_params[:profile], backend[:display], result)
        filename = "tickets-#{get_params[:profile].name}-#{backend[:display]}.xls"
      end
      break
    end
    if content
      send_data(
        content,
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

    if params[:timeRange] == 'realtime'
      start_at = (Time.zone.now - 60.minutes)
      stop_at = Time.zone.now
      range = 'minute'
    elsif params[:timeRange] == 'day'
      date = Date.parse("#{params[:year]}-#{params[:month]}-#{params[:day]}").to_s
      start_at = Time.zone.parse("#{date}T00:00:00Z")
      stop_at = Time.zone.parse("#{date}T23:59:59Z")
      range = 'hour'
    elsif params[:timeRange] == 'week'
      start_week_at = Date.commercial(params[:year].to_i, params[:week].to_i)
      stop_week_at = start_week_at.end_of_week
      start_at = Time.zone.parse("#{start_week_at.year}-#{start_week_at.month}-#{start_week_at.day}T00:00:00Z")
      stop_at = Time.zone.parse("#{stop_week_at.year}-#{stop_week_at.month}-#{stop_week_at.day}T23:59:59Z")
      range = 'week'
    elsif params[:timeRange] == 'month'
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

  def sheet(profile, title, result)

    params[:timezone] ||= Setting.get('timezone_default')

    # Create a new Excel workbook
    temp_file = Tempfile.new('time_tracking.xls')
    workbook = WriteExcel.new(temp_file)

    # Add a worksheet
    worksheet = workbook.add_worksheet
    worksheet.set_row(0, 18)
    worksheet.set_column(0, 0, 10)
    worksheet.set_column(1, 1, 34)
    worksheet.set_column(2, 2, 10)
    worksheet.set_column(3, 3, 10)
    worksheet.set_column(4, 8, 20)
    worksheet.set_column(11, 0, 20)
    worksheet.set_column(12, 0, 20)
    worksheet.set_column(13, 0, 20)

    # Add and define a format
    format = workbook.add_format
    format.set_bold
    format.set_size(14)
    format.set_color('black')

    # Write a formatted and unformatted string, row and column notation.
    worksheet.write_string(0, 0, "Tickets: #{profile.name} (#{title})", format)

    format_header = workbook.add_format
    format_header.set_italic
    format_header.set_bg_color('gray')
    format_header.set_color('white')

    format_time = workbook.add_format(num_format: 'yyyy-mm-dd hh:mm:ss')
    format_date = workbook.add_format(num_format: 'yyyy-mm-dd')

    format_footer = workbook.add_format
    format_footer.set_italic
    format_footer.set_color('gray')
    format_footer.set_size(8)

    worksheet.write_string(2, 0, '#', format_header)
    worksheet.write_string(2, 1, 'Title', format_header)
    worksheet.write_string(2, 2, 'State', format_header)
    worksheet.write_string(2, 3, 'Priority', format_header)
    worksheet.write_string(2, 4, 'Group', format_header)
    worksheet.write_string(2, 5, 'Owner', format_header)
    worksheet.write_string(2, 6, 'Customer', format_header)
    worksheet.write_string(2, 7, 'Organization', format_header)
    worksheet.write_string(2, 8, 'Create Channel', format_header)
    worksheet.write_string(2, 9, 'Sender', format_header)
    worksheet.write_string(2, 10, 'Tags', format_header)
    worksheet.write_string(2, 11, 'Created at', format_header)
    worksheet.write_string(2, 12, 'Updated at', format_header)
    worksheet.write_string(2, 13, 'Closed at', format_header)

    # ObjectManager attributes
    header_column = 14
    # needs to be skipped
    objects = ObjectManager::Attribute.where(editable:         true,
                                             active:           true,
                                             to_create:        false,
                                             object_lookup_id: ObjectLookup.lookup(name: 'Ticket').id)
                                      .pluck(:name, :display, :data_type, :data_option)
                                      .map { |name, display, data_type, data_option| { name: name, display: display, data_type: data_type, data_option: data_option } }
    objects.each do |object|
      worksheet.set_column(header_column, 0, 16)
      worksheet.write_string(2, header_column, object[:display].capitalize, format_header)
      header_column += 1
    end

    row = 2
    result[:ticket_ids].each do |ticket_id|

      ticket = Ticket.lookup(id: ticket_id)
      row += 1
      worksheet.write_string(row, 0, ticket.number)
      worksheet.write_string(row, 1, ticket.title)
      worksheet.write_string(row, 2, ticket.state.name)
      worksheet.write_string(row, 3, ticket.priority.name)
      worksheet.write_string(row, 4, ticket.group.name)
      worksheet.write_string(row, 5, ticket.owner.fullname)
      worksheet.write_string(row, 6, ticket.customer.fullname)
      worksheet.write_string(row, 7, ticket.try(:organization).try(:name))
      worksheet.write_string(row, 8, ticket.create_article_type.name)
      worksheet.write_string(row, 9, ticket.create_article_sender.name)
      worksheet.write_string(row, 10, ticket.tag_list.join(','))

      worksheet.write_date_time(row, 11, time_in_localtime_for_excel(ticket.created_at, params[:timezone]), format_time)
      worksheet.write_date_time(row, 12, time_in_localtime_for_excel(ticket.updated_at, params[:timezone]), format_time)
      worksheet.write_date_time(row, 13, time_in_localtime_for_excel(ticket.close_at, params[:timezone]), format_time) if ticket.close_at.present?

      # Object Manager attributes
      column = 14
      # We already queried ObjectManager::Attributes, so we just use objects
      objects.each do |object|
        key = object[:name]
        case object[:data_type]
        when 'boolean', 'select'
          value = ticket.send(key.to_sym)
          if object[:data_option] && object[:data_option]['options'] && object[:data_option]['options'][ticket.send(key.to_sym)]
            value = object[:data_option]['options'][ticket.send(key.to_sym)]
          end
          worksheet.write_string(row, column, value)
        when 'datetime'
          worksheet.write_date_time(row, column, time_in_localtime_for_excel(ticket.send(key.to_sym), params[:timezone]), format_time) if ticket.send(key.to_sym).present?
        when 'date'
          worksheet.write_date_time(row, column, ticket.send(key.to_sym).to_s, format_date) if ticket.send(key.to_sym).present?
        when 'integer'
          worksheet.write_number(row, column, ticket.send(key.to_sym))
        else
          # for text, integer and tree select
          worksheet.write_string(row, column, ticket.send(key.to_sym).to_s)
        end
        column += 1
      end
    rescue => e
      Rails.logger.error "SKIP: #{e.message}"

    end

    row += 2
    worksheet.write_string(row, 0, "#{Translation.translate(current_user.locale, 'Timezone')}: #{params[:timezone]}", format_footer)

    workbook.close

    # read file again
    file = File.new(temp_file, 'r')
    contents = file.read
    file.close
    contents
  end

  def time_in_localtime_for_excel(time, timezone)
    return if time.blank?

    if timezone.present?
      offset = time.in_time_zone(timezone).utc_offset
      time += offset
    end
    local_time = time.utc.iso8601.to_s.sub(/Z$/, '')
    local_time.sub(/T/, ' ')
  end
end
