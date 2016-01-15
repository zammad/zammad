# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/
module Ticket::Overviews

=begin

all overview by user

  result = Ticket::Overviews.all(
    :current_user => User.find(123),
  )

returns

  result = [overview1, overview2]

=end

  def self.all (data)

    # get customer overviews
    if data[:current_user].role?('Customer')
      role = Role.find_by( name: 'Customer' )
      overviews = if data[:current_user].organization_id && data[:current_user].organization.shared
                    Overview.where( role_id: role.id, active: true )
                  else
                    Overview.where( role_id: role.id, organization_shared: false, active: true )
                  end
      return overviews
    end

    # get agent overviews
    return if !data[:current_user].role?( 'Agent' )
    role = Role.find_by( name: 'Agent' )
    Overview.where( role_id: role.id, active: true )
  end

=begin

selected overview by user

  result = Ticket::Overviews.list(
    current_user: User.find(123),
    view:         'some_view_url',
  )

returns

  result = {
    tickets:       tickets,                # [ticket1, ticket2, ticket3]
    tickets_count: tickets_count,          # count of tickets
    overview:      overview_selected_raw,  # overview attributes
  }

=end

  def self.list (data)

    overviews = all(data)
    return if !overviews

    # build up attributes hash
    overview_selected     = nil
    overview_selected_raw = nil

    overviews.each { |overview|

      # remember selected view
      if data[:view] && data[:view] == overview.link
        overview_selected     = overview
        overview_selected_raw = Marshal.load( Marshal.dump(overview.attributes) )
      end
    }

    if data[:view] && !overview_selected
      fail "No such view '#{data[:view]}'"
    end

    # get only tickets with permissions
    access_condition = Ticket.access_condition( data[:current_user] )

    # overview meta for navbar
    if !overview_selected

      # loop each overview
      result = []
      overviews.each { |overview|

        query_condition, bind_condition = Ticket.selector2sql(overview.condition, data[:current_user])

        # get count
        count = Ticket.where( access_condition ).where( query_condition, *bind_condition ).count()

        # get meta info
        all = {
          name: overview.name,
          prio: overview.prio,
          link: overview.link,
        }

        # push to result data
        result.push all.merge( { count: count } )
      }
      return result
    end

    # get result list
    if data[:array]
      order_by = overview_selected[:order][:by].to_s + ' ' + overview_selected[:order][:direction].to_s
      if overview_selected.group_by && !overview_selected.group_by.empty?
        order_by = overview_selected.group_by + '_id, ' + order_by
      end

      query_condition, bind_condition = Ticket.selector2sql(overview_selected.condition, data[:current_user])

      tickets = Ticket.select('id')
                      .where( access_condition )
                      .where( query_condition, *bind_condition )
                      .order( order_by )
                      .limit( 500 )

      ticket_ids = []
      tickets.each { |ticket|
        ticket_ids.push ticket.id
      }

      tickets_count = Ticket.where( access_condition ).where( query_condition, *bind_condition ).count()

      return {
        ticket_ids: ticket_ids,
        tickets_count: tickets_count,
        overview: overview_selected_raw,
      }
    end

    # get tickets for overview
    data[:start_page] ||= 1
    query_condition, bind_condition = Ticket.selector2sql(overview_selected.condition, data[:current_user])
    tickets = Ticket.where( access_condition )
                    .where( query_condition, *bind_condition )
                    .order( overview_selected[:order][:by].to_s + ' ' + overview_selected[:order][:direction].to_s )

    tickets_count = Ticket.where( access_condition ).where( query_condition, *bind_condition ).count()

    {
      tickets: tickets,
      tickets_count: tickets_count,
      overview: overview_selected_raw,
    }
  end

end
