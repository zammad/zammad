# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/
module ApplicationModel::SearchIndexBase

=begin

collect data to index and send to backend

  ticket = Ticket.find(123)
  result = ticket.search_index_update_backend

returns

  result = true # false

=end

  def search_index_update_backend
    return if !self.class.search_index_support_config

    # fill up with search data
    attributes = search_index_attribute_lookup
    return if !attributes

    # update backend
    SearchIndexBackend.add(self.class.to_s, attributes)
  end

=begin

get data to store in search index

  ticket = Ticket.find(123)
  result = ticket.search_index_data

returns

  result = {
    attribute1: 'some value',
    attribute2: ['value 1', 'value 2'],
    ...
  }

=end

  def search_index_data
    attributes = {}
    %w(name note).each { |key|
      next if !self[key]
      next if self[key].respond_to?('empty?') && self[key].empty?
      attributes[key] = self[key]
    }
    return if attributes.empty?
    attributes
  end

=begin

lookup name of ref. objects

  ticket = Ticket.find(3)
  attributes = ticket.search_index_attribute_lookup

returns

  attributes # object with lookup data

=end

  def search_index_attribute_lookup

    attributes = self.attributes
    self.attributes.each { |key, value|
      next if !value

      # get attribute name
      attribute_name_with_id = key.to_s
      attribute_name         = key.to_s
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
    }

    # default ignored attributes
    config = self.class.search_index_support_config
    if config
      ignore_attributes = {}
      if config[:ignore_attributes]
        config[:ignore_attributes].each { |key, value|
          ignore_attributes[key] = value
        }
      end

      # remove ignored attributes
      ignore_attributes.each { |key, value|
        next if value != true
        attributes.delete(key.to_s)
      }
    end

    attributes
  end
end
