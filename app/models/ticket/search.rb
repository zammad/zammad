# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

module Ticket::Search

=begin

search tickets

  result = Ticket.search(
    :current_user => User.find(123),
    :query        => 'search something',
    :limit        => 15,
  )

returns

  result = [ticket_model1, ticket_model2]


search tickets

  result = Ticket.search(
    :current_user => User.find(123),
    :query        => 'search something',
    :limit        => 15,
    :full         => 0
  )

returns

  result = [1,3,5,6,7]

=end

  def search (params)

    # get params
    query        = params[:query]
    limit        = params[:limit] || 12
    current_user = params[:current_user]
    full         = false
    if params[:full] || !params.has_key?(:full)
      full = true
    end

    # try search index backend
    if !params[:detail] && SearchIndexBackend.enabled?
      query_extention = {}
      query_extention['bool'] = {}
      query_extention['bool']['must'] = []

      if current_user.is_role('Agent')
        groups = Group.joins(:users).
        where( 'groups_users.user_id = ?', current_user.id ).
        where( 'groups.active = ?', true )
        group_condition = []
        groups.each {|group|
          group_condition.push group.name
        }
        access_condition = {
          'query_string' => { 'default_field' => 'Ticket.group.name', 'query' => "\"#{group_condition.join('" OR "')}\"" }
        }
        query_extention['bool']['must'].push access_condition
      else
        if !current_user.organization || ( !current_user.organization.shared || current_user.organization.shared == false )
          access_condition = {
            'query_string' => { 'default_field' => 'Ticket.customer_id', 'query' => current_user.id }
          }
          #  customer_id: XXX
          #          conditions = [ 'customer_id = ?', current_user.id ]
        else
          access_condition = {
            'query_string' => { 'query' => "Ticket.customer_id:#{current_user.id} OR Ticket.organization_id:#{current_user.organization.id}" }
          }
          # customer_id: XXX OR organization_id: XXX
          #          conditions = [ '( customer_id = ? OR organization_id = ? )', current_user.id, current_user.organization.id ]
        end
        query_extention['bool']['must'].push access_condition
      end

      ids = SearchIndexBackend.search( query, limit, 'Ticket', query_extention )
      if !full
        return ids
      end
      tickets = []
      ids.each { |id|
        tickets.push Ticket.lookup( :id => id )
      }
      return tickets
    end

    # fallback do sql query
    access_condition = []
    if current_user.is_role('Agent')
      group_ids = Group.select( 'groups.id' ).joins(:users).
      where( 'groups_users.user_id = ?', current_user.id ).
      where( 'groups.active = ?', true ).
      map( &:id )
      access_condition = [ 'group_id IN (?)', group_ids ]
    else
      if !current_user.organization || ( !current_user.organization.shared || current_user.organization.shared == false )
        access_condition = [ 'customer_id = ?', current_user.id ]
      else
        access_condition = [ '( customer_id = ? OR organization_id = ? )', current_user.id, current_user.organization.id ]
      end
    end

    # do query
    # - stip out * we already search for *query* -
    if query
      query.gsub! '*', ''
      tickets_all = Ticket.select('DISTINCT(tickets.id)').
      where(access_condition).
      where( '( `tickets`.`title` LIKE ? OR `tickets`.`number` LIKE ? OR `ticket_articles`.`body` LIKE ? OR `ticket_articles`.`from` LIKE ? OR `ticket_articles`.`to` LIKE ? OR `ticket_articles`.`subject` LIKE ?)', "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%" ).
      joins(:articles).
      order('`tickets`.`created_at` DESC').
      limit(limit)
    else
      tickets_all = Ticket.select('DISTINCT(tickets.id)').
      where(access_condition).
      where(params[:condition]).
      order('`tickets`.`created_at` DESC').
      limit(limit)
    end

    # build result list
    if !full
      ids = []
      tickets_all.each { |ticket|
        ids.push ticket.id
      }
      return ids
    end

    tickets = []
    tickets_all.each { |ticket|
      tickets.push Ticket.lookup( :id => ticket.id )
    }
    return tickets
  end

end
