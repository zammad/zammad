# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class User
  module Search
    extend ActiveSupport::Concern

    # methods defined here are going to extend the class, not the instance of it
    class_methods do

=begin

search user preferences

  result = User.search_preferences(user_model)

returns if user has permissions to search

  result = {
    prio: 1000,
    direct_search_index: true
  }

returns if user has no permissions to search

  result = false

=end

      def search_preferences(current_user)
        return false if !current_user.permissions?('ticket.agent') && !current_user.permissions?('admin.user')

        {
          prio:                2000,
          direct_search_index: true,
        }
      end

=begin

search user

  result = User.search(
    query: 'some search term',
    limit: 15,
    offset: 100,
    current_user: user_model,
  )

or with certain role_ids | permissions

  result = User.search(
    query: 'some search term',
    limit: 15,
    offset: 100,
    current_user: user_model,
    role_ids: [1,2,3],
    group_ids: [1,2,3],
    permissions: ['ticket.agent']

    # sort single column
    sort_by: 'created_at',
    order_by: 'asc',

    # sort multiple columns
    sort_by: [ 'created_at', 'updated_at' ],
    order_by: [ 'asc', 'desc' ],
  )

returns

  result = [user_model1, user_model2, ...]

=end

      def search(params)

        # get params
        query = params[:query]
        limit = params[:limit] || 10
        offset = params[:offset] || 0
        current_user = params[:current_user]

        sql_helper = ::SqlHelper.new(object: self)

        # check sort - positions related to order by
        sort_by = sql_helper.get_sort_by(params, %w[active updated_at])

        # check order - positions related to sort by
        order_by = sql_helper.get_order_by(params, %w[desc desc])

        # enable search only for agents and admins
        return [] if !search_preferences(current_user)

        # lookup for roles of permission
        if params[:permissions].present?
          params[:role_ids] ||= []
          role_ids = Role.with_permissions(params[:permissions]).pluck(:id)
          params[:role_ids].concat(role_ids)
        end

        # try search index backend
        if SearchIndexBackend.enabled?
          query_extension = {}
          if params[:role_ids].present?
            query_extension['bool'] ||= {}
            query_extension['bool']['must'] ||= []
            if !params[:role_ids].is_a?(Array)
              params[:role_ids] = [params[:role_ids]]
            end
            access_condition = {
              'query_string' => { 'default_field' => 'role_ids', 'query' => "\"#{params[:role_ids].join('" OR "')}\"" }
            }
            query_extension['bool']['must'].push access_condition
          end
          if params[:group_ids].present?
            query_extension['bool'] ||= {}
            query_extension['bool']['must'] ||= []
            user_ids = []
            params[:group_ids].each do |group_id, access|
              user_ids |= User.group_access(group_id.to_i, access).pluck(:id)
            end

            return [] if user_ids.blank?

            query_extension['bool']['must'].push({ 'terms' => { '_id' => user_ids } })
          end

          items = SearchIndexBackend.search(query, 'User', limit:           limit,
                                                           query_extension: query_extension,
                                                           from:            offset,
                                                           sort_by:         sort_by,
                                                           order_by:        order_by)
          users = []
          items.each do |item|
            user = User.lookup(id: item[:id])
            next if !user

            users.push user
          end
          return users
        end

        order_sql = sql_helper.get_order(sort_by, order_by, 'users.updated_at DESC')

        # fallback do sql query
        # - stip out * we already search for *query* -
        query.delete! '*'

        statement = User
        if params[:role_ids]
          statement = statement.joins(:roles).where('roles.id' => params[:role_ids])
        end
        if params[:group_ids]
          user_ids = []
          params[:group_ids].each do |group_id, access|
            user_ids |= User.group_access(group_id.to_i, access).pluck(:id)
          end
          statement = if user_ids.present?
                        statement.where(id: user_ids)
                      else
                        statement.none
                      end
        end

        statement.where(
          '(users.firstname LIKE ? OR users.lastname LIKE ? OR users.email LIKE ? OR users.login LIKE ?) AND users.id != 1', "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%"
        )
        .order(Arel.sql(order_sql))
        .offset(offset)
        .limit(limit)
      end
    end
  end
end
