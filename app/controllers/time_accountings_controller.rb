# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class TimeAccountingsController < ApplicationController
  prepend_before_action { authentication_check(permission: 'admin.time_accounting') }

  def by_ticket

    year = params[:year] || Time.zone.now.year
    month = params[:month] || Time.zone.now.month

    start_periode = Time.zone.parse("#{year}-#{month}-01")
    end_periode = start_periode.end_of_month

    time_unit = {}
    Ticket::TimeAccounting.where('created_at >= ? AND created_at <= ?', start_periode, end_periode).pluck(:ticket_id, :time_unit, :created_by_id).each do |record|
      if !time_unit[record[0]]
        time_unit[record[0]] = {
          time_unit: 0,
          agent_id: record[2],
        }
      end
      time_unit[record[0]][:time_unit] += record[1]
    end
    customers = {}
    organizations = {}
    agents = {}
    results = []
    time_unit.each do |ticket_id, local_time_unit|
      ticket = Ticket.lookup(id: ticket_id)
      next if !ticket
      if !customers[ticket.customer_id]
        customers[ticket.customer_id] = '-'
        if ticket.customer_id
          customer_user = User.lookup(id: ticket.customer_id)
          if customer_user
            customers[ticket.customer_id] = customer_user.fullname
          end
        end
      end
      if !organizations[ticket.organization_id]
        organizations[ticket.organization_id] = '-'
        if ticket.organization_id
          organization = Organization.lookup(id: ticket.organization_id)
          if organization
            organizations[ticket.organization_id] = organization.name
          end
        end
      end
      if !customers[local_time_unit[:agent_id]]
        agent_user = User.lookup(id: local_time_unit[:agent_id])
        agent = '-'
        if agent_user
          agents[local_time_unit[:agent_id]] = agent_user.fullname
        end
      end
      result = {
        ticket: ticket.attributes,
        time_unit: local_time_unit[:time_unit],
        customer: customers[ticket.customer_id],
        organization: organizations[ticket.organization_id],
        agent: agents[local_time_unit[:agent_id]],
      }
      results.push result
    end

    if params[:download]
      header = [
        {
          name: 'Ticket#',
          width: 15,
        },
        {
          name: 'Title',
          width: 30,
        },
        {
          name: 'Customer',
          width: 20,
        },
        {
          name: 'Organization',
          width: 20,
        },
        {
          name: 'Agent',
          width: 20,
        },
        {
          name: 'Time Units',
          width: 10,
        },
        {
          name: 'Time Units Total',
          width: 10,
        },
        {
          name: 'Created at',
          width: 10,
        },
        {
          name: 'Closed at',
          width: 10,
        },
        {
          name: 'Close Escalation At',
          width: 10,
        },
        {
          name: 'Close In Min',
          width: 10,
        },
        {
          name: 'Close Diff In Min',
          width: 10,
        },
        {
          name: 'First Response At',
          width: 10,
        },
        {
          name: 'First Response Escalation At',
          width: 10,
        },
        {
          name: 'First Response In Min',
          width: 10,
        },
        {
          name: 'First Response Diff In Min',
          width: 10,
        },
        {
          name: 'Update Escalation At',
          width: 10,
        },
        {
          name: 'Update In Min',
          width: 10,
        },
        {
          name: 'Update Diff In Min',
          width: 10,
        },
        {
          name: 'Last Contact At',
          width: 10,
        },
        {
          name: 'Last Contact Agent At',
          width: 10,
        },
        {
          name: 'Last Contact Customer At',
          width: 10,
        },
        {
          name: 'Article Count',
          width: 10,
        },
        {
          name: 'Escalation At',
          width: 10,
        },
      ]
      objects = ObjectManager::Attribute.where(editable: true,
                                               active: true,
                                               object_lookup_id: ObjectLookup.lookup(name: 'Ticket').id)
                                        .pluck(:name, :display, :data_type, :data_option)
                                        .map { |name, display, data_type, data_option| { name: name, display: display, data_type: data_type, data_option: data_option } }
      objects.each do |object|
        header.push({ name: object[:display], width: 10 })
      end

      result = []
      results.each do |row|
        row[:ticket].each_key do |field|
          next if row[:ticket][field].blank?
          next if !row[:ticket][field].is_a?(ActiveSupport::TimeWithZone)

          row[:ticket][field] = row[:ticket][field].iso8601
        end

        result_row = [
          row[:ticket]['number'],
          row[:ticket]['title'],
          row[:customer],
          row[:organization],
          row[:agent],
          row[:time_unit],
          row[:ticket]['time_unit'],
          row[:ticket]['created_at'],
          row[:ticket]['close_at'],
          row[:ticket]['close_escalation_at'],
          row[:ticket]['close_in_min'],
          row[:ticket]['close_diff_in_min'],
          row[:ticket]['first_response_at'],
          row[:ticket]['first_response_escalation_at'],
          row[:ticket]['first_response_in_min'],
          row[:ticket]['first_response_diff_in_min'],
          row[:ticket]['update_escalation_at'],
          row[:ticket]['update_in_min'],
          row[:ticket]['update_diff_in_min'],
          row[:ticket]['last_contact_at'],
          row[:ticket]['last_contact_agent_at'],
          row[:ticket]['last_contact_customer_at'],
          row[:ticket]['article_count'],
          row[:ticket]['escalation_at'],
        ]

        # needed to get human values for boolean/select rather than true/false values
        ticket = Ticket.lookup(id: row[:ticket]['id'])

        # Object Manager attributes
        # We already queried ObjectManager::Attributes, so we just use objects
        objects.each do |object|
          key = object[:name]
          case object[:data_type]
          when 'boolean', 'select'
            value = object[:data_option]['options'][ticket.send(key.to_sym)]
            value.present? ? result_row.push(value) : result_row.push('')
          when 'datetime', 'date'
            row[:ticket][key].present? ? result_row.push(row[:ticket][key].to_time.iso8601) : result_row.push('')
          else
            # for text, integer and tree select
            row[:ticket][key].present? ? result_row.push(row[:ticket][key]) : result_row.push('')
          end
        end

        result.push result_row
      end
      content = sheet("By Ticket #{year}-#{month}", header, result)
      send_data(
        content,
        filename: "by_ticket-#{year}-#{month}.xls",
        type: 'application/vnd.ms-excel',
        disposition: 'attachment'
      )
      return
    end

    render json: results
  end

  def by_customer

    year = params[:year] || Time.zone.now.year
    month = params[:month] || Time.zone.now.month

    start_periode = Time.zone.parse("#{year}-#{month}-01")
    end_periode = start_periode.end_of_month

    time_unit = {}
    Ticket::TimeAccounting.where('created_at >= ? AND created_at <= ?', start_periode, end_periode).pluck(:ticket_id, :time_unit, :created_by_id).each do |record|
      if !time_unit[record[0]]
        time_unit[record[0]] = {
          time_unit: 0,
          agent_id: record[2],
        }
      end
      time_unit[record[0]][:time_unit] += record[1]
    end

    customers = {}
    time_unit.each do |ticket_id, local_time_unit|
      ticket = Ticket.lookup(id: ticket_id)
      next if !ticket
      if !customers[ticket.customer_id]
        organization = nil
        if ticket.organization_id
          organization = Organization.lookup(id: ticket.organization_id).attributes
        end
        customers[ticket.customer_id] = {
          customer: User.lookup(id: ticket.customer_id).attributes,
          organization: organization,
          time_unit: local_time_unit[:time_unit],
        }
        next
      end
      customers[ticket.customer_id][:time_unit] += local_time_unit[:time_unit]
    end
    results = []
    customers.each_value do |content|
      results.push content
    end

    if params[:download]
      header = [
        {
          name: 'Customer',
          width: 30,
        },
        {
          name: 'Organization',
          width: 30,
        },
        {
          name: 'Time Units',
          width: 10,
        }
      ]
      result = []
      results.each do |row|
        customer_name = User.find(row[:customer]['id']).fullname
        organization_name = ''
        if row[:organization].present?
          organization_name = row[:organization]['name']
        end
        result_row = [customer_name, organization_name, row[:time_unit]]
        result.push result_row
      end
      content = sheet("By Customer #{year}-#{month}", header, result)
      send_data(
        content,
        filename: "by_customer-#{year}-#{month}.xls",
        type: 'application/vnd.ms-excel',
        disposition: 'attachment'
      )
      return
    end

    render json: results
  end

  def by_organization

    year = params[:year] || Time.zone.now.year
    month = params[:month] || Time.zone.now.month

    start_periode = Time.zone.parse("#{year}-#{month}-01")
    end_periode = start_periode.end_of_month

    time_unit = {}
    Ticket::TimeAccounting.where('created_at >= ? AND created_at <= ?', start_periode, end_periode).pluck(:ticket_id, :time_unit, :created_by_id).each do |record|
      if !time_unit[record[0]]
        time_unit[record[0]] = {
          time_unit: 0,
          agent_id: record[2],
        }
      end
      time_unit[record[0]][:time_unit] += record[1]
    end

    organizations = {}
    time_unit.each do |ticket_id, local_time_unit|
      ticket = Ticket.lookup(id: ticket_id)
      next if !ticket
      next if !ticket.organization_id
      if !organizations[ticket.organization_id]
        organizations[ticket.organization_id] = {
          organization: Organization.lookup(id: ticket.organization_id).attributes,
          time_unit: local_time_unit[:time_unit],
        }
        next
      end
      organizations[ticket.organization_id][:time_unit] += local_time_unit[:time_unit]
    end
    results = []
    organizations.each_value do |content|
      results.push content
    end

    if params[:download]
      header = [
        {
          name: 'Organization',
          width: 40,
        },
        {
          name: 'Time Units',
          width: 20,
        }
      ]
      result = []
      results.each do |row|
        organization_name = ''
        if row[:organization].present?
          organization_name = row[:organization]['name']
        end
        result_row = [organization_name, row[:time_unit]]
        result.push result_row
      end
      content = sheet("By Organization #{year}-#{month}", header, result)
      send_data(
        content,
        filename: "by_organization-#{year}-#{month}.xls",
        type: 'application/vnd.ms-excel',
        disposition: 'attachment'
      )
      return
    end

    render json: results
  end

  private

  def sheet(title, header, result)

    # Create a new Excel workbook
    temp_file = Tempfile.new('time_tracking.xls')
    workbook = WriteExcel.new(temp_file)

    # Add a worksheet
    worksheet = workbook.add_worksheet

    # Add and define a format
    format = workbook.add_format  # Add a format
    format.set_bold
    format.set_size(14)
    format.set_color('black')
    worksheet.set_row(0, 0, header.count)

    # Write a formatted and unformatted string, row and column notation.
    worksheet.write_string(0, 0, title, format)

    format_header = workbook.add_format  # Add a format
    format_header.set_italic
    format_header.set_bg_color('gray')
    format_header.set_color('white')
    count = 0
    header.each do |item|
      if item[:width]
        worksheet.set_column(count, count, item[:width])
      end
      worksheet.write_string(2, count, item[:name], format_header)
      count += 1
    end

    row_count = 2
    result.each do |row|
      row_count += 1
      row_item_count = 0
      row.each do |item|
        if item.acts_like?(:date)
          worksheet.write_date_time(row_count, row_item_count, item.to_time.iso8601)
        else
          worksheet.write_string(row_count, row_item_count, item)
        end
        row_item_count += 1
      end
    end

    workbook.close

    # read file again
    file = File.new(temp_file, 'r')
    contents = file.read
    file.close
    contents
  end

end
