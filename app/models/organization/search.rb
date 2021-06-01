# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Organization
  module Search
    extend ActiveSupport::Concern

    # methods defined here are going to extend the class, not the instance of it
    class_methods do

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
          prio:                1500,
          direct_search_index: true,
        }
      end

=begin

search organizations

  result = Organization.search(
    current_user: User.find(123),
    query: 'search something',
    limit: 15,
    offset: 100,

    # sort single column
    sort_by: 'created_at',
    order_by: 'asc',

    # sort multiple columns
    sort_by: [ 'created_at', 'updated_at' ],
    order_by: [ 'asc', 'desc' ],
  )

returns

  result = [organization_model1, organization_model2]

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

        # try search index backend
        if SearchIndexBackend.enabled?
          items = SearchIndexBackend.search(query, 'Organization', limit:    limit,
                                                                   from:     offset,
                                                                   sort_by:  sort_by,
                                                                   order_by: order_by)
          organizations = []
          items.each do |item|
            organization = Organization.lookup(id: item[:id])
            next if !organization

            organizations.push organization
          end
          return organizations
        end

        order_select_sql = sql_helper.get_order_select(sort_by, order_by, 'organizations.updated_at')
        order_sql        = sql_helper.get_order(sort_by, order_by, 'organizations.updated_at ASC')

        # fallback do sql query
        # - stip out * we already search for *query* -
        query.delete! '*'
        organizations = Organization.where_or_cis(%i[name note], "%#{query}%")
                                    .order(Arel.sql(order_sql))
                                    .offset(offset)
                                    .limit(limit)
                                    .to_a

        # use result independent of size if an explicit offset is given
        # this is the case for e.g. paginated searches
        return organizations if params[:offset].present?
        return organizations if organizations.length > 3

        # if only a few organizations are found, search for names of users
        organizations_by_user = Organization.select("DISTINCT(organizations.id), #{order_select_sql}")
                                            .joins('LEFT OUTER JOIN users ON users.organization_id = organizations.id')
                                            .where(User.or_cis(%i[firstname lastname email], "%#{query}%"))
                                            .order(Arel.sql(order_sql))
                                            .limit(limit)

        organizations_by_user.each do |organization_by_user|

          organization_exists = false
          organizations.each do |organization|
            next if organization.id != organization_by_user.id

            organization_exists = true
            break
          end

          # get model with full data
          next if organization_exists

          organizations.push Organization.find(organization_by_user.id)
        end
        organizations
      end
    end
  end
end
