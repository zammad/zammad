# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Organization
  module Search

=begin

search organizations preferences

  result = Organization.search_preferences(user_model)

returns if user has permissions to search

  result = {
    prio: 1000,
    direct_search_index: true
  }

returns if user has no permissions to search

  result = false

=end

    def search_preferences(current_user)
      return false if !current_user.permissions?('ticket.agent') && !current_user.permissions?('admin.organization')
      {
        prio: 1000,
        direct_search_index: true,
      }
    end

=begin

search organizations

  result = Organization.search(
    current_user: User.find(123),
    query: 'search something',
    limit: 15,
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
      return [] if !search_preferences(current_user)

      # try search index backend
      if SearchIndexBackend.enabled?
        items = SearchIndexBackend.search(query, limit, 'Organization')
        organizations = []
        items.each { |item|
          organization = Organization.lookup(id: item[:id])
          next if !organization
          organizations.push organization
        }
        return organizations
      end

      # fallback do sql query
      # - stip out * we already search for *query* -
      query.delete! '*'
      organizations = Organization.where(
        'name LIKE ? OR note LIKE ?', "%#{query}%", "%#{query}%"
      ).order('name').limit(limit)

      # if only a few organizations are found, search for names of users
      if organizations.length <= 3
        organizations_by_user = Organization.select('DISTINCT(organizations.id), organizations.name').joins('LEFT OUTER JOIN users ON users.organization_id = organizations.id').where(
          'users.firstname LIKE ? or users.lastname LIKE ? or users.email LIKE ?', "%#{query}%", "%#{query}%", "%#{query}%"
        ).order('organizations.name').limit(limit)
        organizations_by_user.each { |organization_by_user|
          organization_exists = false
          organizations.each { |organization|
            if organization.id == organization_by_user.id
              organization_exists = true
            end
          }

          # get model with full data
          if !organization_exists
            organizations.push Organization.find(organization_by_user.id)
          end
        }
      end
      organizations
    end
  end
end
