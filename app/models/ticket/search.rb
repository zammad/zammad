# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

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

    # try search index backend
    if Setting.get('es_url')
      ids = SearchIndexBackend.search( query, limit, 'Ticket' )
      tickets = []
      ids.each { |id|
        tickets.push Ticket.lookup( :id => id )
      }
      return tickets
    end

    # fallback do sql query
    # do query
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