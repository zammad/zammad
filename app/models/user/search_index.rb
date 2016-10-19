# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class User
  module SearchIndex

=begin

get data to store in search index

  user = User.find(2)
  result = user.search_index_data

returns

  result = {
    attribute1: 'some value',
    attribute2: ['value 1', 'value 2'],
    ...
  }

=end

    def search_index_data
      attributes = {}
      self.attributes.each { |key, value|
        next if key == 'created_at'
        next if key == 'updated_at'
        next if key == 'created_by_id'
        next if key == 'updated_by_id'
        next if key == 'preferences'
        next if key == 'password'
        next if !value
        next if value.respond_to?('empty?') && value.empty?
        attributes[key] = value
      }
      return if attributes.empty?

      if attributes['organization_id']
        organization = Organization.lookup(id: attributes['organization_id'])
        if organization
          attributes['organization'] = organization.name
          attributes['organization_ref'] = organization.search_index_data
        end
      end

      attributes
    end

  end
end
