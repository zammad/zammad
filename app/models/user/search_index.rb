# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class User
  module SearchIndex
    extend ActiveSupport::Concern

=begin

lookup name of ref. objects

  user = User.find(123)
  attributes = user.search_index_attribute_lookup

returns

  attributes # object with lookup data

=end

    def search_index_attribute_lookup
      attributes = super

      attributes['permissions'] = []
      permissions_with_child_ids.each do |permission_id|
        permission = ::Permission.lookup(id: permission_id)
        next if !permission

        attributes['permissions'].push permission.name
      end
      attributes['role_ids'] = role_ids

      attributes
    end

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
      self.attributes.each do |key, value|
        next if key == 'password'
        next if !value
        next if value.respond_to?('blank?') && value.blank?

        attributes[key] = value
      end
      return if attributes.blank?

      if attributes['organization_id'].present?
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
