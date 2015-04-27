# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class User
  module Search

=begin

search user

  result = User.search(
    :query        => 'some search term'
    :limit        => 15,
    :current_user => user_model,
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
      return [] if !current_user.is_role('Agent') && !current_user.is_role(Z_ROLENAME_ADMIN)

      # try search index backend
      if SearchIndexBackend.enabled?
        items = SearchIndexBackend.search( query, limit, 'User' )
        users = []
        items.each { |item|
          users.push User.lookup( id: item[:id] )
        }
        return users
      end

      # fallback do sql query
      # - stip out * we already search for *query* -
      query.gsub! '*', ''
      if params[:role_ids]
        users = User.joins(:roles).where( 'roles.id' => params[:role_ids] ).where(
          '(users.firstname LIKE ? or users.lastname LIKE ? or users.email LIKE ?) AND users.id != 1', "%#{query}%", "%#{query}%", "%#{query}%",
        ).order('firstname').limit(limit)
      else
        users = User.where(
          '(firstname LIKE ? or lastname LIKE ? or email LIKE ?) AND id != 1', "%#{query}%", "%#{query}%", "%#{query}%",
        ).order('firstname').limit(limit)
      end
      users
    end
  end
end
