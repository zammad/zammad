# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class User
  module SearchIndex
    extend ActiveSupport::Concern

    def search_index_attribute_lookup(include_references: true)
      attributes = super
      attributes['fullname'] = fullname
      attributes.delete('password')

      if include_references
        attributes['permissions'] = []
        permissions_with_child_ids.each do |permission_id|
          permission = ::Permission.lookup(id: permission_id)
          next if !permission

          attributes['permissions'].push permission.name
        end
        attributes['role_ids'] = role_ids

        attributes['organization_ids'] = organization_ids
        attributes['organizations']    = organizations.each_with_object([]) do |organization, result|
          result << organization.search_index_attribute_lookup(include_references: false)
        end
      end

      attributes
    end
  end
end
