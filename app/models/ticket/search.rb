# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/
module Ticket::Search

=begin

search tickets preferences

  result = Ticket.search_preferences(user_model)

returns if user has permissions to search

  result = {
    prio: 3000,
    direct_search_index: false
  }

returns if user has no permissions to search

  result = false

=end

  def search_preferences(_current_user)
    {
      prio: 3000,
      direct_search_index: false,
    }
  end

=begin

search tickets via search index

  result = Ticket.search(
    current_user: User.find(123),
    query:        'search something',
    limit:        15,
  )

returns

  result = [ticket_model1, ticket_model2]

search tickets via search index

  result = Ticket.search(
    current_user: User.find(123),
    query:        'search something',
    limit:        15,
    full:         false,
  )

returns

  result = [1,3,5,6,7]

search tickets via database

  result = Ticket.search(
    current_user: User.find(123),
    condition: {
      'tickets.owner_id' => {
        operator: 'is',
        value: user.id,
      },
      'tickets.state_id' => {
        operator: 'is',
        value: Ticket::State.where(
          state_type_id: Ticket::StateType.where(
            name: [
              'pending reminder',
              'pending action',
            ],
          ).map(&:id),
        },
      ),
    },
    limit: 15,
    full: false,
  )

returns

  result = [1,3,5,6,7]

=end

  def search(params)

    # get params
    query        = params[:query]
    limit        = params[:limit] || 12
    current_user = params[:current_user]
    full         = false
    if params[:full] || !params.key?(:full)
      full = true
    end

    # try search index backend
    if !params[:condition] && SearchIndexBackend.enabled?
      query_extention = {}
      query_extention['bool'] = {}
      query_extention['bool']['must'] = []

      if current_user.role?('Agent')
        groups = Group.joins(:users)
                      .where('groups_users.user_id = ?', current_user.id)
                      .where('groups.active = ?', true)
        group_condition = []
        groups.each {|group|
          group_condition.push group.name
        }
        access_condition = {
          'query_string' => { 'default_field' => 'Ticket.group.name', 'query' => "\"#{group_condition.join('" OR "')}\"" }
        }
      else
        access_condition = if !current_user.organization || ( !current_user.organization.shared || current_user.organization.shared == false )
                             {
                               'query_string' => { 'default_field' => 'Ticket.customer_id', 'query' => current_user.id }
                             }
                           #  customer_id: XXX
                           #          conditions = [ 'customer_id = ?', current_user.id ]
                           else
                             {
                               'query_string' => { 'query' => "Ticket.customer_id:#{current_user.id} OR Ticket.organization_id:#{current_user.organization.id}" }
                             }
                             # customer_id: XXX OR organization_id: XXX
                             #          conditions = [ '( customer_id = ? OR organization_id = ? )', current_user.id, current_user.organization.id ]
                           end
      end

      query_extention['bool']['must'].push access_condition

      items = SearchIndexBackend.search(query, limit, 'Ticket', query_extention)
      if !full
        ids = []
        items.each {|item|
          ids.push item[:id]
        }
        return ids
      end
      tickets = []
      items.each { |item|
        tickets.push Ticket.lookup(id: item[:id])
      }
      return tickets
    end

    # fallback do sql query
    access_condition = Ticket.access_condition(current_user)

    # do query
    # - stip out * we already search for *query* -
    if query
      query.delete! '*'
      tickets_all = Ticket.select('DISTINCT(tickets.id), tickets.created_at')
                          .where(access_condition)
                          .where('(tickets.title LIKE ? OR tickets.number LIKE ? OR ticket_articles.body LIKE ? OR ticket_articles.from LIKE ? OR ticket_articles.to LIKE ? OR ticket_articles.subject LIKE ?)', "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%" )
                          .joins(:articles)
                          .order('tickets.created_at DESC')
                          .limit(limit)
    else
      query_condition, bind_condition = selector2sql(params[:condition])
      tickets_all = Ticket.select('DISTINCT(tickets.id), tickets.created_at')
                          .where(access_condition)
                          .where(query_condition, *bind_condition)
                          .order('tickets.created_at DESC')
                          .limit(limit)
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
      tickets.push Ticket.lookup(id: ticket.id)
    }
    tickets
  end
end
