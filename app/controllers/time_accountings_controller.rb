# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class TimeAccountingsController < ApplicationController
  prepend_before_action { authentication_check(permission: 'admin.time_accounting') }

  def by_ticket

    year = params[:year] || Time.zone.now.year
    month = params[:month] || Time.zone.now.month

    start_periode = Date.parse("#{year}-#{month}-01")
    end_periode = start_periode.end_of_month

    time_unit = {}
    Ticket::TimeAccounting.where('created_at >= ? AND created_at <= ?', start_periode, end_periode).pluck(:ticket_id, :time_unit, :created_by_id).each { |record|
      if !time_unit[record[0]]
        time_unit[record[0]] = {
          time_unit: 0,
          agent_id: record[2],
        }
      end
      time_unit[record[0]][:time_unit] += record[1]
    }
    customers = {}
    organizations = {}
    agents = {}
    results = []
    time_unit.each { |ticket_id, local_time_unit|
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
    }
    render json: results
  end

  def by_customer

    year = params[:year] || Time.zone.now.year
    month = params[:month] || Time.zone.now.month

    start_periode = Date.parse("#{year}-#{month}-01")
    end_periode = start_periode.end_of_month

    time_unit = {}
    Ticket::TimeAccounting.where('created_at >= ? AND created_at <= ?', start_periode, end_periode).pluck(:ticket_id, :time_unit, :created_by_id).each { |record|
      if !time_unit[record[0]]
        time_unit[record[0]] = {
          time_unit: 0,
          agent_id: record[2],
        }
      end
      time_unit[record[0]][:time_unit] += record[1]
    }

    customers = {}
    time_unit.each { |ticket_id, local_time_unit|
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
    }
    results = []
    customers.each { |_customer_id, content|
      results.push content
    }
    render json: results
  end

  def by_organization

    year = params[:year] || Time.zone.now.year
    month = params[:month] || Time.zone.now.month

    start_periode = Date.parse("#{year}-#{month}-01")
    end_periode = start_periode.end_of_month

    time_unit = {}
    Ticket::TimeAccounting.where('created_at >= ? AND created_at <= ?', start_periode, end_periode).pluck(:ticket_id, :time_unit, :created_by_id).each { |record|
      if !time_unit[record[0]]
        time_unit[record[0]] = {
          time_unit: 0,
          agent_id: record[2],
        }
      end
      time_unit[record[0]][:time_unit] += record[1]
    }

    organizations = {}
    time_unit.each { |ticket_id, local_time_unit|
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
    }
    results = []
    organizations.each { |_customer_id, content|
      results.push content
    }
    render json: results
  end

end
