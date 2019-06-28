# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
module ApplicationModel::CanLookupSearchIndexAttributes
  extend ActiveSupport::Concern

=begin

lookup name of ref. objects

  ticket = Ticket.find(3)
  attributes = ticket.search_index_attribute_lookup

returns

  attributes # object with lookup data

=end

  def search_index_attribute_lookup

    attributes = self.attributes
    self.attributes.each do |key, value|
      next if !value

      # get attribute name
      attribute_name = key.to_s
      next if attribute_name[-3, 3] != '_id'

      attribute_name = attribute_name[ 0, attribute_name.length - 3 ]

      # check if attribute method exists
      next if !respond_to?(attribute_name)

      # check if method has own class
      relation_class = send(attribute_name).class
      next if !relation_class

      # lookup ref object
      relation_model = relation_class.lookup(id: value)
      next if !relation_model

      # get name of ref object
      value = nil
      if relation_model.respond_to?('search_index_data')
        value = relation_model.send('search_index_data')
      end

      if relation_model.respond_to?('name')
        value = relation_model.send('name')
      end

      next if !value

      # save name of ref object
      attributes[ attribute_name ] = value
    end

    ignored_attributes = self.class.instance_variable_get(:@search_index_attributes_ignored) || []
    return attributes if ignored_attributes.blank?

    ignored_attributes.each do |attribute|
      attributes.delete(attribute.to_s)
    end

    attributes
  end
end
