# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

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

    # default ignored attributes
    ignore_attributes = {
      :created_at               => true,
      :updated_at               => true,
      :created_by_id            => true,
      :updated_by_id            => true,
      :active                   => true,
    }
    if self.class.search_index_support_config[:ignore_attributes]
      self.class.search_index_support_config[:ignore_attributes].each {|key, value|
        ignore_attributes[key] = value
      }
    end

    # remove ignored attributes
    attributes = self.attributes
    ignore_attributes.each {|key, value|
      next if value != true
      attributes.delete( key.to_s )
    }

    # fill up with search data
    attributes = search_index_attribute_lookup(attributes, self)
    return if !attributes

    # update backend
    if self.class.column_names.include? 'active'
      if self.active
        SearchIndexBackend.add( self.class.to_s, attributes )
      else
        SearchIndexBackend.remove( self.class.to_s, self.id )
      end
    else
      SearchIndexBackend.add( self.class.to_s, attributes )
    end
  end

=begin

get data to store in search index

  ticket = Ticket.find(123)
  result = ticket.search_index_data

returns

  result = true # false

=end

  def search_index_data
    data = []
    ['name', 'note'].each { |key|
      data.push self[key] if self[key]
    }
    return data[0] if !data[1]
    data
  end

  private

=begin

lookup name of ref. objects

  attributes = search_index_attribute_lookup(attributes, Ticket)

returns

  attributes # object with lookup data

=end

  def search_index_attribute_lookup(attributes, ref_object)
    attributes_new = {}
    attributes.each {|key, value|
      next if !value

      # get attribute name
      attribute_name = key.to_s
      next if attribute_name[-3,3] != '_id'
      attribute_name = attribute_name[ 0, attribute_name.length-3 ]

      # check if attribute method exists
      next if !ref_object.respond_to?( attribute_name )

      # check if method has own class
      relation_class = ref_object.send(attribute_name).class
      next if !relation_class

      # lookup ref object
      relation_model = relation_class.lookup( :id => value )
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
    attributes_new.merge(attributes)
  end

end