# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class ObjectLookup < ApplicationModel
  @@cache_object = {}

  def self.by_id( id )

    # use cache
    return @@cache_object[ id ] if @@cache_object[ id ]

    # lookup
    object_lookup = ObjectLookup.lookup( :id => id )
    return if !object_lookup
    @@cache_object[ id ] = object_lookup.name
    object_lookup.name
  end

  def self.by_name( name )

    # use cache
    return @@cache_object[ name ] if @@cache_object[ name ]

    # lookup
    object_lookup = ObjectLookup.lookup( :name => name )
    if object_lookup
      @@cache_object[ name ] = object_lookup.id
      return object_lookup.id
    end

    # create
    object_lookup = ObjectLookup.create(
      :name => name
    )
    @@cache_object[ name ] = object_lookup.id
    object_lookup.id
  end

end
