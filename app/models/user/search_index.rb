# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class User
  module SearchIndex
    extend ActiveSupport::Concern

    def search_index_attribute_lookup(include_references: true)
      attributes = super
      attributes.delete('password')

      if include_references
        attributes['permissions'] = []
        permissions_with_child_ids.each do |permission_id|
          permission = ::Permission.lookup(id: permission_id)
          next if !permission

          attributes['permissions'].push permission.name
        end
        attributes['role_ids'] = role_ids
      end

      attributes
    end
  end
end
