# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

module User::Search

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
    return [] if !current_user.is_role('Agent') && !current_user.is_role('Admin')

    # try search index backend
    if SearchIndexBackend.enabled?
      ids = SearchIndexBackend.search( query, limit, 'User' )
      users = []
      ids.each { |id|
        users.push User.lookup( :id => id )
      }
      return users
    end

    # fallback do sql query
    # - stip out * we already search for *query* -
    query.gsub! '*', ''
    users = User.find(
      :all,
      :limit      => limit,
      :conditions => ['(firstname LIKE ? or lastname LIKE ? or email LIKE ?) AND id != 1', "%#{query}%", "%#{query}%", "%#{query}%"],
      :order      => 'firstname'
    )
    return users
  end

end
