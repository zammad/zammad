# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class TypeLookup < ApplicationModel
  @@cache_object = {} # rubocop:disable Style/ClassVars

  def self.by_id( id )

    # use cache
    return @@cache_object[ id ] if @@cache_object[ id ]

    # lookup
    lookup = self.lookup( id: id )
    return if !lookup
    @@cache_object[ id ] = lookup.name
    lookup.name
  end

  def self.by_name( name )

    # use cache
    return @@cache_object[ name ] if @@cache_object[ name ]

    # lookup
    lookup = self.lookup( name: name )
    if lookup
      @@cache_object[ name ] = lookup.id
      return lookup.id
    end

    # create
    lookup = create(
      name: name
    )
    @@cache_object[ name ] = lookup.id
    lookup.id
  end

end
