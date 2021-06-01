# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Organization
  module SearchIndex
    extend ActiveSupport::Concern

    def search_index_attribute_lookup(include_references: true)
      attributes = super

      if include_references

        # add org members for search index data
        attributes['members'] = []
        users = User.where(organization_id: id)
        users.each do |user|
          attributes['members'].push user.search_index_attribute_lookup(include_references: false)
        end
      end

      attributes
    end
  end
end
