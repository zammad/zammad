# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class ObjectLookup < ApplicationModel

  def self.by_id(id)
    # lookup
    lookup = self.lookup(id: id)
    return if !lookup

    lookup.name
  end

  def self.by_name(name)
    # lookup
    lookup = self.lookup(name: name)
    if lookup
      return lookup.id
    end

    # create
    lookup = create(name: name)
    lookup.id
  end

=begin

This function returns the rails class for the frontend class name (legacy). To reverse this, check Class::to_app_model.

  result = ObjectLookup.find_by(name: 'TicketArticle').to_class

returns

  result = Ticket::Article

=end

  def to_class
    self.class.to_class(name)
  end

=begin

This function returns the rails class for the frontend class name (legacy). To reverse this, check Class::to_app_model.

  result = ObjectLookup.to_class('TicketArticle')

returns

  result = Ticket::Article

=end

  def self.to_class(name)
    Auth::RequestCache.fetch_value('ObjectLookup/to_class') do
      Models.all.keys.index_by { it.to_app_model.to_s }
    end[name.to_s]
  end
end
