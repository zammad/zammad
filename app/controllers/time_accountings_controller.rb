# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class TimeAccountingsController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def index
    model_index_render(ticket_time_accounting_scope, params)
  end

  def show
    model_show_render(ticket_time_accounting_scope, params)
  end

  def create
    model_create_render(ticket_time_accounting_scope, params)
  end

  def update
    model_update_render(ticket_time_accounting_scope, params)
  end

  def destroy
    model_references_check(Ticket::TimeAccounting, params)
    model_destroy_render(ticket_time_accounting_scope, params)
  end

  def by_activity
    year  = params[:year] || Time.zone.now.year
    month = params[:month] || Time.zone.now.month

    start_period = Time.zone.parse("#{year}-#{month}-01")
    end_period   = start_period.end_of_month

    records = Ticket::TimeAccounting
      .where(created_at: (start_period..end_period))
      .pluck(:ticket_id, :ticket_article_id, :time_unit, :type_id, :created_by_id, :created_at)

    customers     = {}
    organizations = {}
    types         = {}
    agents        = {}
    results       = []
    records.each do |record|
      ticket = Ticket.lookup(id: record[0])
      next if !ticket

      customers[ticket.customer_id]         ||= User.lookup(id: ticket.customer_id).fullname
      organizations[ticket.organization_id] ||= Organization.lookup(id: ticket.organization_id)&.name
      types[record[3]]                      ||= Ticket::TimeAccounting::Type.lookup(id: record[3])&.name
      agents[record[4]]                     ||= User.lookup(id: record[4])

      result = if params[:download]
                 [
                   ticket.number,
                   ticket.title,
                   customers[ticket.customer_id] || '-',
                   organizations[ticket.organization_id] || '-',
                   agents[record[4]].fullname,
                   agents[record[4]].login,
                   record[2],
                   *([types[record[3]] || '-'] if Setting.get('time_accounting_types')),
                   record[5]
                 ]
               else
                 {
                   ticket:       ticket.attributes,
                   time_unit:    record[2],
                   type:         (types[record[3]] || '-' if Setting.get('time_accounting_types')),
                   customer:     customers[ticket.customer_id] || '-',
                   organization: organizations[ticket.organization_id] || '-',
                   agent:        agents[record[4]].fullname,
                   created_at:   record[5],
                 }.compact
               end

      results.push result
    end

    if !params[:download]
      results = results.last(params[:limit].to_i) if params[:limit]
      render json: results
      return
    end

    header = [
      {
        name:  __('Ticket#'),
        width: 20,
      },
      {
        name:  __('Title'),
        width: 20,
      },
      {
        name:  "#{__('Customer')} - #{__('Name')}",
        width: 20,
      },
      {
        name:  __('Organization'),
        width: 20,
      },
      {
        name:  "#{__('Agent')} - #{__('Name')}",
        width: 20,
      },
      {
        name:  "#{__('Agent')} - #{__('Login')}",
        width: 20,
      },
      {
        name:      __('Time Units'),
        width:     10,
        data_type: 'float'
      },
      *(if Setting.get('time_accounting_types')
          [{
            name:  __('Activity Type'),
            width: 20,
          }]
        end),
      {
        name:  __('Created at'),
        width: 20,
      },
    ]

    excel = ExcelSheet.new(
      title:    "By Activity #{year}-#{month}",
      header:   header,
      records:  results,
      timezone: params[:timezone],
      locale:   current_user.locale,
    )
    send_data(
      excel.content,
      filename:    "by_activity-#{year}-#{month}.xlsx",
      type:        ExcelSheet::CONTENT_TYPE,
      disposition: 'attachment'
    )
  end

  def by_ticket
    year  = params[:year] || Time.zone.now.year
    month = params[:month] || Time.zone.now.month

    start_period = Time.zone.parse("#{year}-#{month}-01")
    end_period   = start_period.end_of_month

    time_unit = Ticket::TimeAccounting
      .where(created_at: (start_period..end_period))
      .pluck(:ticket_id, :time_unit, :created_by_id)
      .each_with_object({}) do |record, memo|
        if !memo[record[0]]
          memo[record[0]] = {
            time_unit: 0,
            agent_id:  record[2],
          }
        end
        memo[record[0]][:time_unit] += record[1]
      end

    if !params[:download]
      customers = {}
      organizations = {}
      agents = {}
      results = []
      time_unit.each do |ticket_id, local_time_unit|
        ticket = Ticket.lookup(id: ticket_id)
        next if !ticket

        customers[ticket.customer_id]         ||= User.lookup(id: ticket.customer_id).fullname
        organizations[ticket.organization_id] ||= Organization.lookup(id: ticket.organization_id)&.name
        agents[local_time_unit[:agent_id]]    ||= User.lookup(id: local_time_unit[:agent_id]).fullname

        result = {
          ticket:       ticket.attributes,
          time_unit:    local_time_unit[:time_unit],
          customer:     customers[ticket.customer_id] || '-',
          organization: organizations[ticket.organization_id] || '-',
          agent:        agents[local_time_unit[:agent_id]],
        }
        results.push result
      end

      results = results.last(params[:limit].to_i) if params[:limit]
      render json: results
      return
    end

    ticket_ids = []
    additional_attributes = []
    additional_attributes_header = [{ display: __('Time Units'), name: 'time_unit_for_range', width: 10, data_type: 'float' }]
    time_unit.each do |ticket_id, local_time_unit|
      ticket_ids.push ticket_id
      additional_attribute = {
        time_unit_for_range: local_time_unit[:time_unit],
      }
      additional_attributes.push additional_attribute
    end

    excel = ExcelSheet::Ticket.new(
      title:                        "Tickets: #{year}-#{month}",
      ticket_ids:                   ticket_ids,
      additional_attributes:        additional_attributes,
      additional_attributes_header: additional_attributes_header,
      timezone:                     params[:timezone],
      locale:                       current_user.locale,
    )

    send_data(
      excel.content,
      filename:    "by_ticket-#{year}-#{month}.xlsx",
      type:        ExcelSheet::CONTENT_TYPE,
      disposition: 'attachment'
    )
  end

  def by_customer
    year  = params[:year] || Time.zone.now.year
    month = params[:month] || Time.zone.now.month

    start_period = Time.zone.parse("#{year}-#{month}-01")
    end_period   = start_period.end_of_month

    results = Ticket::TimeAccounting
      .where(created_at: (start_period..end_period))
      .pluck(:ticket_id, :time_unit, :created_by_id)
      .each_with_object({}) do |record, memo|
        memo[record[0]] ||= {
          time_unit: 0,
          agent_id:  record[2],
        }
        memo[record[0]][:time_unit] += record[1]
      end
      .each_with_object({}) do |(ticket_id, local_time_unit), memo|
        ticket = Ticket.lookup(id: ticket_id)
        next if !ticket

        memo[ticket.customer_id] ||= {}
        memo[ticket.customer_id][ticket.organization_id] ||= {
          customer:     User.lookup(id: ticket.customer_id).attributes,
          organization: Organization.lookup(id: ticket.organization_id)&.attributes,
          time_unit:    0,
        }
        memo[ticket.customer_id][ticket.organization_id][:time_unit] += local_time_unit[:time_unit]
      end
      .values
      .map(&:values)
      .flatten

    if params[:download]
      header = [
        {
          name:  __('Customer'),
          width: 30,
        },
        {
          name:  __('Organization'),
          width: 30,
        },
        {
          name:      __('Time Units'),
          width:     10,
          data_type: 'float'
        }
      ]
      records = results.map do |row|
        customer_name = User.find(row[:customer]['id']).fullname
        organization_name = ''
        if row[:organization].present?
          organization_name = row[:organization]['name']
        end
        [customer_name, organization_name, row[:time_unit]]
      end

      excel = ExcelSheet.new(
        title:    "By Customer #{year}-#{month}",
        header:   header,
        records:  records,
        timezone: params[:timezone],
        locale:   current_user.locale,
      )
      send_data(
        excel.content,
        filename:    "by_customer-#{year}-#{month}.xlsx",
        type:        ExcelSheet::CONTENT_TYPE,
        disposition: 'attachment'
      )
      return
    end

    results = results.last(params[:limit].to_i) if params[:limit]
    render json: results
  end

  def by_organization
    year  = params[:year] || Time.zone.now.year
    month = params[:month] || Time.zone.now.month

    start_period = Time.zone.parse("#{year}-#{month}-01")
    end_period   = start_period.end_of_month

    results = Ticket::TimeAccounting
      .where(created_at: (start_period..end_period))
      .pluck(:ticket_id, :time_unit, :created_by_id)
      .each_with_object({}) do |record, memo|
        memo[record[0]] ||= {
          time_unit: 0,
          agent_id:  record[2],
        }
        memo[record[0]][:time_unit] += record[1]
      end
      .each_with_object({}) do |(ticket_id, local_time_unit), memo|
        ticket = Ticket.lookup(id: ticket_id)
        next if !ticket
        next if !ticket.organization_id

        memo[ticket.organization_id] ||= {
          organization: Organization.lookup(id: ticket.organization_id).attributes,
          time_unit:    0,
        }
        memo[ticket.organization_id][:time_unit] += local_time_unit[:time_unit]
      end
      .values

    if params[:download]
      header = [
        {
          name:  __('Organization'),
          width: 40,
        },
        {
          name:      __('Time Units'),
          width:     20,
          data_type: 'float',
        }
      ]

      records = results.map do |row|
        organization_name = ''
        if row[:organization].present?
          organization_name = row[:organization]['name']
        end
        [organization_name, row[:time_unit]]
      end

      excel = ExcelSheet.new(
        title:    "By Organization #{year}-#{month}",
        header:   header,
        records:  records,
        timezone: params[:timezone],
        locale:   current_user.locale,
      )
      send_data(
        excel.content,
        filename:    "by_organization-#{year}-#{month}.xlsx",
        type:        ExcelSheet::CONTENT_TYPE,
        disposition: 'attachment'
      )
      return
    end

    results = results.last(params[:limit].to_i) if params[:limit]
    render json: results
  end

  private

  def ticket_time_accounting_scope
    @ticket_time_accounting_scope ||= begin
      if params[:ticket_id]
        Ticket::TimeAccounting.where(ticket_id: params[:ticket_id])
      else
        Ticket::TimeAccounting
      end
    end
  end
end
