# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

module Organization::Search

=begin

search organizations

  result = Organization.search(
    :current_user => User.find(123),
    :query        => 'search something',
    :limit        => 15,
  )

returns

  result = [organization_model1, organization_model2]

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
      ids = SearchIndexBackend.search( query, limit, 'Organization' )
      organizations = []
      ids.each { |id|
        organizations.push Organization.lookup( :id => id )
      }
      return organizations
    end

    # fallback do sql query
    # - stip out * we already search for *query* -
    query.gsub! '*', ''
    organizations = Organization.find(
      :all,
      :limit      => limit,
      :conditions => ['name LIKE ? OR note LIKE ?', "%#{query}%", "%#{query}%"],
      :order      => 'name'
    )

    # if only a few organizations are found, search for names of users
    if organizations.length <= 3
      organizations_by_user = Organization.select('DISTINCT(organizations.id)').joins('LEFT OUTER JOIN users ON users.organization_id = organizations.id').find(
        :all,
        :limit      => limit,
        :conditions => ['users.firstname LIKE ? or users.lastname LIKE ? or users.email LIKE ?', "%#{query}%", "%#{query}%", "%#{query}%"],
        :order      => 'organizations.name'
      )
      organizations_by_user.each {|organization_by_user|
        organization_exists = false
        organizations.each {|organization|
          if organization.id == organization_by_user.id
            organization_exists = true
          end
        }

        # get model with full data
        if !organization_exists
          organizations.push Organization.find(organization_by_user)
        end
      }
    end
    organizations
  end
end
