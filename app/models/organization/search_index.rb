# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Organization
  module SearchIndex

=begin

lookup name of ref. objects

  organization = Organization.find(123)
  attributes = organization.search_index_attribute_lookup(attributes, Organization)

returns

  attributes # object with lookup data

=end

    def search_index_attribute_lookup(attributes, ref_object)
      attributes_new = {}
      attributes.each {|key, value|
        next if !value

        # get attribute name
        attribute_name = key.to_s
        next if attribute_name[-3, 3] != '_id'
        attribute_name = attribute_name[ 0, attribute_name.length - 3 ]

        # check if attribute method exists
        next if !ref_object.respond_to?(attribute_name)

        # check if method has own class
        relation_class = ref_object.send(attribute_name).class
        next if !relation_class

        # lookup ref object
        relation_model = relation_class.lookup(id: value)
        next if !relation_model

        # get name of ref object
        value = nil
        if relation_model.respond_to?('search_index_data')
          value = relation_model.send('search_index_data')
        end
        next if !value

        # save name of ref object
        attributes_new[ attribute_name ] = value
        attributes.delete(key)
      }

      # add org member for search index data
      attributes['member'] = []
      users = User.where(organization_id: id)
      users.each { |user|
        attributes['member'].push user.search_index_data
      }

      attributes_new.merge(attributes)
    end
  end
end
