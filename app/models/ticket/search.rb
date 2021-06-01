# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Ticket::Search
  extend ActiveSupport::Concern

  # methods defined here are going to extend the class, not the instance of it
  class_methods do

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
        prio:                3000,
        direct_search_index: false,
      }
    end

=begin

search tickets via search index

  result = Ticket.search(
    current_user: User.find(123),
    query:        'search something',
    limit:        15,
    offset:       100,
  )

returns

  result = [ticket_model1, ticket_model2]

search tickets via search index

  result = Ticket.search(
    current_user: User.find(123),
    query:        'search something',
    limit:        15,
    offset:       100,
    full:         false,
  )

returns

  result = [1,3,5,6,7]

search tickets via database

  result = Ticket.search(
    current_user: User.find(123),
    query: 'some query', # query or condition is required
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
    offset: 100,

    # sort single column
    sort_by: 'created_at',
    order_by: 'asc',

    # sort multiple columns
    sort_by: [ 'created_at', 'updated_at' ],
    order_by: [ 'asc', 'desc' ],

    full: false,
  )

returns

  result = [1,3,5,6,7]

=end

    def search(params)

      # get params
      query        = params[:query]
      condition    = params[:condition]
      limit        = params[:limit] || 12
      offset       = params[:offset] || 0
      current_user = params[:current_user]
      full         = false
      if params[:full] == true || params[:full] == 'true' || !params.key?(:full)
        full = true
      end

      sql_helper = ::SqlHelper.new(object: self)

      # check sort
      sort_by = sql_helper.get_sort_by(params, 'updated_at')

      # check order
      order_by = sql_helper.get_order_by(params, 'desc')

      # try search index backend
      if condition.blank? && SearchIndexBackend.enabled?

        query_or = []
        if current_user.permissions?('ticket.agent')
          group_ids = current_user.group_ids_access('read')
          if group_ids.present?
            access_condition = {
              'query_string' => { 'default_field' => 'group_id', 'query' => "\"#{group_ids.join('" OR "')}\"" }
            }
            query_or.push(access_condition)
          end
        end
        if current_user.permissions?('ticket.customer')
          access_condition = if !current_user.organization || ( !current_user.organization.shared || current_user.organization.shared == false )
                               {
                                 'query_string' => { 'default_field' => 'customer_id', 'query' => current_user.id }
                               }
                             #  customer_id: XXX
                             #          conditions = [ 'customer_id = ?', current_user.id ]
                             else
                               {
                                 'query_string' => { 'query' => "customer_id:#{current_user.id} OR organization_id:#{current_user.organization.id}" }
                               }
                               # customer_id: XXX OR organization_id: XXX
                               #          conditions = [ '( customer_id = ? OR organization_id = ? )', current_user.id, current_user.organization.id ]
                             end
          query_or.push(access_condition)
        end

        return [] if query_or.blank?

        query_extension = {
          bool: {
            must: [
              {
                bool: {
                  should: query_or,
                },
              },
            ],
          }
        }

        items = SearchIndexBackend.search(query, 'Ticket', limit:           limit,
                                                           query_extension: query_extension,
                                                           from:            offset,
                                                           sort_by:         sort_by,
                                                           order_by:        order_by)
        if !full
          ids = []
          items.each do |item|
            ids.push item[:id]
          end
          return ids
        end
        tickets = []
        items.each do |item|
          ticket = Ticket.lookup(id: item[:id])
          next if !ticket

          tickets.push ticket
        end
        return tickets
      end

      # fallback do sql query
      access_condition = Ticket.access_condition(current_user, 'read')

      # do query
      # - stip out * we already search for *query* -

      order_select_sql = sql_helper.get_order_select(sort_by, order_by, 'tickets.updated_at')
      order_sql        = sql_helper.get_order(sort_by, order_by, 'tickets.updated_at DESC')
      if query
        query.delete! '*'
        tickets_all = Ticket.select("DISTINCT(tickets.id), #{order_select_sql}")
                            .where(access_condition)
                            .where('(tickets.title LIKE ? OR tickets.number LIKE ? OR ticket_articles.body LIKE ? OR ticket_articles.from LIKE ? OR ticket_articles.to LIKE ? OR ticket_articles.subject LIKE ?)', "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%" )
                            .joins(:articles)
                            .order(Arel.sql(order_sql))
                            .offset(offset)
                            .limit(limit)
      else
        query_condition, bind_condition, tables = selector2sql(condition)
        tickets_all = Ticket.select("DISTINCT(tickets.id), #{order_select_sql}")
                            .joins(tables)
                            .where(access_condition)
                            .where(query_condition, *bind_condition)
                            .order(Arel.sql(order_sql))
                            .offset(offset)
                            .limit(limit)
      end

      # build result list
      if !full
        ids = []
        tickets_all.each do |ticket|
          ids.push ticket.id
        end
        return ids
      end

      tickets = []
      tickets_all.each do |ticket|
        tickets.push Ticket.lookup(id: ticket.id)
      end
      tickets
    end
  end

end
