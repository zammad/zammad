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
    if data[:current_user].is_role('Customer')
      role = data[:current_user].is_role( 'Customer' )
      if data[:current_user].organization_id && data[:current_user].organization.shared
        overviews = Overview.where( role_id: role.id, active: true )
      else
        overviews = Overview.where( role_id: role.id, organization_shared: false, active: true )
      end
      return overviews
    end

    # get agent overviews
    role = data[:current_user].is_role( 'Agent' )
    return if !role
    Overview.where( role_id: role.id, active: true )
  end

=begin

selected overview by user

  result = Ticket::Overviews.list(
    :current_user => User.find(123),
    :view         => 'some_view_url',
  )

returns

  result = {
    :tickets       => tickets,                # [ticket1, ticket2, ticket3]
    :tickets_count => tickets_count,          # count of tickets
    :overview      => overview_selected_raw,  # overview attributes
  }

=end

  def self.list (data)

    overviews = self.all(data)
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

      # replace e.g. 'current_user.id' with current_user.id
      overview.condition.each { |item, value |
        if value && value.class.to_s == 'String'
          parts = value.split( '.', 2 )
          if parts[0] && parts[1] && parts[0] == 'current_user'
            overview.condition[item] = data[:current_user][parts[1].to_sym]
          end
        end
      }
    }

    if data[:view] && !overview_selected
      raise "No such view '#{ data[:view] }'"
    end

    # sortby
    # prio
    # state
    # group
    # customer

    # order
    # asc
    # desc

    # groupby
    # prio
    # state
    # group
    # customer

    #    all = attributes[:myopenassigned]
    #    all.merge( { :group_id => groups } )

    #    @tickets = Ticket.where(:group_id => groups, attributes[:myopenassigned] ).limit(params[:limit])
    # get only tickets with permissions
    if data[:current_user].is_role('Customer')
      group_ids = Group.select( 'groups.id' ).
      where( 'groups.active = ?', true ).
      map( &:id )
    else
      group_ids = Group.select( 'groups.id' ).joins(:users).
      where( 'groups_users.user_id = ?', [ data[:current_user].id ] ).
      where( 'groups.active = ?', true ).
      map( &:id )
    end

    # overview meta for navbar
    if !overview_selected

      # loop each overview
      result = []
      overviews.each { |overview|

        # get count
        count = Ticket.where( group_id: group_ids ).where( _condition( overview.condition ) ).count()

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
      tickets = Ticket.select( 'id' ).
      where( group_id: group_ids ).
      where( _condition( overview_selected.condition ) ).
      order( order_by ).
      limit( 500 )

      ticket_ids = []
      tickets.each { |ticket|
        ticket_ids.push ticket.id
      }

      tickets_count = Ticket.where( group_id: group_ids ).
      where( _condition( overview_selected.condition ) ).
      count()

      return {
        ticket_ids: ticket_ids,
        tickets_count: tickets_count,
        overview: overview_selected_raw,
      }
    end

    # get tickets for overview
    data[:start_page] ||= 1
    tickets = Ticket.where( group_id: group_ids ).
    where( _condition( overview_selected.condition ) ).
    order( overview_selected[:order][:by].to_s + ' ' + overview_selected[:order][:direction].to_s )#.
    #      limit( overview_selected.view[ data[:view_mode].to_sym ][:per_page] ).
    #      offset( overview_selected.view[ data[:view_mode].to_sym ][:per_page].to_i * ( data[:start_page].to_i - 1 ) )

    tickets_count = Ticket.where( group_id: group_ids ).
    where( _condition( overview_selected.condition ) ).
    count()

    return {
      tickets: tickets,
      tickets_count: tickets_count,
      overview: overview_selected_raw,
    }
  end

  private
  def self._condition(condition)
    sql  = ''
    bind = [nil]
    condition.each {|key, value|
      if sql != ''
        sql += ' AND '
      end
      if value.class == Array
        sql += " #{key} IN (?)"
        bind.push value
      elsif value.class == Hash || value.class == ActiveSupport::HashWithIndifferentAccess
        time = Time.now
        if value['area'] == 'minute'
          if value['direction'] == 'last'
            time -= value['count'].to_i * 60
          else
            time += value['count'].to_i * 60
          end
        elsif value['area'] == 'hour'
          if value['direction'] == 'last'
            time -= value['count'].to_i * 60 * 60
          else
            time += value['count'].to_i * 60 * 60
          end
        elsif value['area'] == 'day'
          if value['direction'] == 'last'
            time -= value['count'].to_i * 60 * 60 * 24
          else
            time += value['count'].to_i * 60 * 60 * 24
          end
        elsif value['area'] == 'month'
          if value['direction'] == 'last'
            time -= value['count'].to_i * 60 * 60 * 24 * 31
          else
            time += value['count'].to_i * 60 * 60 * 24 * 31
          end
        elsif value['area'] == 'year'
          if value['direction'] == 'last'
            time -= value['count'].to_i * 60 * 60 * 24 * 365
          else
            time += value['count'].to_i * 60 * 60 * 24 * 365
          end
        end
        if value['direction'] == 'last'
          sql += " #{key} > ?"
          bind.push time
        else
          sql += " #{key} < ?"
          bind.push time
        end
      else
        sql += " #{key} = ?"
        bind.push value
      end
    }
    bind[0] = sql
    return bind
  end
end
