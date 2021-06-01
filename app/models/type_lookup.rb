# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class TypeLookup < ApplicationModel

  def self.by_id( id )
    lookup = self.lookup( id: id )
    return if !lookup

    lookup.name
  end

  def self.by_name( name )
    # lookup
    lookup = self.lookup( name: name )
    if lookup
      return lookup.id
    end

    # create
    lookup = create(
      name: name
    )
    lookup.id
  end
end
