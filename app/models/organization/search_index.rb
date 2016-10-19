# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Organization
  module SearchIndex

=begin

lookup name of ref. objects

  organization = Organization.find(123)
  attributes = organization.search_index_attribute_lookup

returns

  attributes # object with lookup data

=end

    def search_index_attribute_lookup
      attributes = super

      # add org members for search index data
      attributes['members'] = []
      users = User.where(organization_id: id)
      users.each { |user|
        attributes['members'].push user.search_index_data
      }

      attributes
    end
  end
end
