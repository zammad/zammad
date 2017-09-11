# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class User
  module Search

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
        prio: 2000,
        direct_search_index: true,
      }
    end

=begin

search user

  result = User.search(
    query: 'some search term',
    limit: 15,
    current_user: user_model,
  )

or with certain role_ids | permissions

  result = User.search(
    query: 'some search term',
    limit: 15,
    current_user: user_model,
    role_ids: [1,2,3],
    permissions: ['ticket.agent']
  )

returns

  result = [user_model1, user_model2, ...]

=end

    def search(params)

      # get params
      query = params[:query]
      limit = params[:limit] || 10
      current_user = params[:current_user]

      # enable search only for agents and admins
      return [] if !search_preferences(current_user)

      # lookup for roles of permission
      if params[:permissions].present?
        params[:role_ids] ||= []
        role_ids = Role.with_permissions(params[:permissions]).map(&:id)
        params[:role_ids].concat(role_ids)
      end

      # try search index backend
      if SearchIndexBackend.enabled?
        query_extention = {}
        if params[:role_ids].present?
          query_extention['bool'] = {}
          query_extention['bool']['must'] = []
          if !params[:role_ids].is_a?(Array)
            params[:role_ids] = [params[:role_ids]]
          end
          access_condition = {
            'query_string' => { 'default_field' => 'role_ids', 'query' => "\"#{params[:role_ids].join('" OR "')}\"" }
          }
          query_extention['bool']['must'].push access_condition
        end
        items = SearchIndexBackend.search(query, limit, 'User', query_extention)
        users = []
        items.each { |item|
          user = User.lookup(id: item[:id])
          next if !user
          users.push user
        }
        return users
      end

      # fallback do sql query
      # - stip out * we already search for *query* -
      query.delete! '*'
      users = if params[:role_ids]
                User.joins(:roles).where('roles.id' => params[:role_ids]).where(
                  '(users.firstname LIKE ? OR users.lastname LIKE ? OR users.email LIKE ? OR users.login LIKE ?) AND users.id != 1', "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%"
                ).order('updated_at DESC').limit(limit)
              else
                User.where(
                  '(firstname LIKE ? OR lastname LIKE ? OR email LIKE ? OR login LIKE ?) AND id != 1', "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%"
                ).order('updated_at DESC').limit(limit)
              end
      users
    end
  end
end
