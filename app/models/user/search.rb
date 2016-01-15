# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

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
      return false if !current_user.role?('Agent') && !current_user.role?(Z_ROLENAME_ADMIN)
      {
        prio: 2000,
        direct_search_index: true,
      }
    end

=begin

search user

  result = User.search(
    query: 'some search term'
    limit: 15,
    current_user: user_model,
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

      # try search index backend
      if SearchIndexBackend.enabled?
        items = SearchIndexBackend.search(query, limit, 'User')
        users = []
        items.each { |item|
          users.push User.lookup(id: item[:id])
        }
        return users
      end

      # fallback do sql query
      # - stip out * we already search for *query* -
      query.delete! '*'
      if params[:role_ids]
        users = User.joins(:roles).where( 'roles.id' => params[:role_ids] ).where(
          '(users.firstname LIKE ? OR users.lastname LIKE ? OR users.email LIKE ? OR users.login LIKE ?) AND users.id != 1', "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%"
        ).order('firstname').limit(limit)
      else
        users = User.where(
          '(firstname LIKE ? OR lastname LIKE ? OR email LIKE ? OR login LIKE ?) AND id != 1', "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%"
        ).order('firstname').limit(limit)
      end
      users
    end
  end
end
