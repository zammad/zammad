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

=end

  def search (params)

    # get params
    query        = params[:query]
    limit        = params[:limit] || 12
    current_user = params[:current_user]

    # try search index backend
    if SearchIndexBackend.enabled?
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
        condition = {
          'query_string' => { 'default_field' => 'Ticket.group.name', 'query' => "\"#{group_condition.join('" OR "')}\"" }
        }
        query_extention['bool']['must'].push condition
      else
        if !current_user.organization || ( !current_user.organization.shared || current_user.organization.shared == false )
          condition = {
            'query_string' => { 'default_field' => 'Ticket.customer_id', 'query' => current_user.id }
          }
          #  customer_id: XXX
          #          conditions = [ 'customer_id = ?', current_user.id ]
        else
          condition = {
            'query_string' => { 'query' => "Ticket.customer_id:#{current_user.id} OR Ticket.organization_id:#{current_user.organization.id}" }
          }
          # customer_id: XXX OR organization_id: XXX
          #          conditions = [ '( customer_id = ? OR organization_id = ? )', current_user.id, current_user.organization.id ]
        end
        query_extention['bool']['must'].push condition
      end

      ids = SearchIndexBackend.search( query, limit, 'Ticket', query_extention )
      tickets = []
      ids.each { |id|
        tickets.push Ticket.lookup( :id => id )
      }
      return tickets
    end

    # fallback do sql query
    conditions = []
    if current_user.is_role('Agent')
      group_ids = Group.select( 'groups.id' ).joins(:users).
      where( 'groups_users.user_id = ?', current_user.id ).
      where( 'groups.active = ?', true ).
      map( &:id )
      conditions = [ 'group_id IN (?)', group_ids ]
    else
      if !current_user.organization || ( !current_user.organization.shared || current_user.organization.shared == false )
        conditions = [ 'customer_id = ?', current_user.id ]
      else
        conditions = [ '( customer_id = ? OR organization_id = ? )', current_user.id, current_user.organization.id ]
      end
    end

    # do query
    # - stip out * we already search for *query* -
    query.gsub! '*', ''
    tickets_all = Ticket.select('DISTINCT(tickets.id)').
    where(conditions).
    where( '( `tickets`.`title` LIKE ? OR `tickets`.`number` LIKE ? OR `ticket_articles`.`body` LIKE ? OR `ticket_articles`.`from` LIKE ? OR `ticket_articles`.`to` LIKE ? OR `ticket_articles`.`subject` LIKE ?)', "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%" ).
    joins(:articles).
    limit(limit).
    order('`tickets`.`created_at` DESC')

    # build result list
    tickets = []
    tickets_all.each do |ticket|
      tickets.push Ticket.lookup( :id => ticket.id )
    end

    tickets
  end

end
