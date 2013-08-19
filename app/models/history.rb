# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

class History < ApplicationModel
  include History::Assets

  self.table_name = 'histories'
  belongs_to :history_type,             :class_name => 'History::Type'
  belongs_to :history_object,           :class_name => 'History::Object'
  belongs_to :history_attribute,        :class_name => 'History::Attribute'
  #  before_validation :check_type, :check_object
  #  attr_writer :history_type, :history_object

  @@cache_type = {}
  @@cache_object = {}
  @@cache_attribute = {}

=begin

add a new history entry for an object

  History.add(
    :history_type      => 'updated',
    :history_object    => 'Ticket',
    :history_attribute => 'ticket_state',
    :o_id              => ticket.id,
    :id_to             => 3,
    :id_from           => 2,
    :value_from        => 'open',
    :value_to          => 'pending',
    :created_by_id     => 1,
    :created_at        => '2013-06-04 10:00:00',
    :updated_at        => '2013-06-04 10:00:00'
  )

=end

  def self.add(data)

    # lookups
    if data[:history_type]
      history_type = self.history_type_lookup( data[:history_type] )
    end
    if data[:history_object]
      history_object = self.history_object_lookup( data[:history_object] )
    end
    related_history_object_id = nil
    if data[:related_history_object]
      related_history_object = self.history_object_lookup( data[:related_history_object] )
      related_history_object_id = related_history_object.id
    end
    history_attribute_id = nil
    if data[:history_attribute]
      history_attribute = self.history_attribute_lookup( data[:history_attribute] )
      history_attribute_id = history_attribute.id
    end

    # create history
    record = {
      :id                          => data[:id],
      :o_id                        => data[:o_id],
      :history_type_id             => history_type.id,
      :history_object_id           => history_object.id,
      :history_attribute_id        => history_attribute_id,
      :related_history_object_id   => related_history_object_id,
      :related_o_id                => data[:related_o_id],
      :value_from                  => data[:value_from],
      :value_to                    => data[:value_to],
      :id_from                     => data[:id_from],
      :id_to                       => data[:id_to],
      :created_at                  => data[:created_at],
      :created_by_id               => data[:created_by_id]
    }
    history_record = nil
    if data[:id]
      history_record = History.where( :id => data[:id] ).first
    end
    if history_record
      history_record.update_attributes(record)
    else
      record_new = History.create(record)
      if record[:id]
        record_new.id = record[:id]
      end
      record_new.save
    end
  end

=begin

remove whole history entries of an object

  History.remove( 'Ticket', 123 )

=end

  def self.remove( requested_object, requested_object_id )
    history_object = History::Object.where( :name => requested_object ).first
    History.where(
      :history_object_id => history_object.id,
      :o_id              => requested_object_id,
    ).destroy_all
  end

=begin

return all histoy entries of an object

  history_list = History.list( 'Ticket', 123 )

=end

  def self.list( requested_object, requested_object_id, related_history_object = nil )
    if !related_history_object
      history_object = self.history_object_lookup( requested_object )
      history = History.where( :history_object_id => history_object.id ).
      where( :o_id => requested_object_id ).
      where( :history_type_id => History::Type.where( :name => ['created', 'updated', 'notification', 'email', 'added', 'removed'] ) ).
      order('created_at ASC, id ASC')
    else
      history_object_requested = self.history_object_lookup( requested_object )
      history_object_related   = self.history_object_lookup( related_history_object )
      history = History.where(
        '((history_object_id = ? AND o_id = ?) OR (history_object_id = ? AND related_o_id = ? )) AND history_type_id IN (?)',
        history_object_requested.id,
        requested_object_id,
        history_object_related.id,
        requested_object_id,
        History::Type.where( :name => ['created', 'updated', 'notification', 'email', 'added', 'removed'] )
      ).
      order('created_at ASC, id ASC')
    end

    return history
  end

  def self.activity_stream( user, limit = 10 )
    #    g = Group.where( :active => true ).joins(:users).where( 'users.id' => user.id )
    #    stream = History.select("distinct(histories.o_id), created_by_id, history_attribute_id, history_type_id, history_object_id, value_from, value_to").
    #      where( :history_type_id   => History::Type.where( :name => ['created', 'updated']) ).
    stream = History.select("distinct(histories.o_id), created_by_id, history_type_id, history_object_id").
    where( :history_object_id => History::Object.where( :name => [ 'Ticket', 'Ticket::Article' ] ) ).
    where( :history_type_id   => History::Type.where( :name => [ 'created', 'updated' ]) ).
    order('created_at DESC, id DESC').
    limit(limit)
    datas = []
    stream.each do |item|
      data = item.attributes
      data['history_object'] = self.history_object_lookup_id( data['history_object_id'] ).name
      data['history_type']   = self.history_type_lookup_id( data['history_type_id'] ).name
      data.delete('history_object_id')
      data.delete('history_type_id')
      datas.push data
      #      item['history_attribute'] = item.history_attribute
    end
    return datas
  end

  def self.activity_stream_fulldata( user, limit = 10 )
    activity_stream = History.activity_stream( user, limit )

    # get related users
    assets = {}
    activity_stream.each {|item|

      # load article ids
      if item['history_object'] == 'Ticket'
        ticket = Ticket.find( item['o_id'] )
        assets = ticket.assets(assets)
      end
      if item['history_object'] == 'Ticket::Article'
        article = Ticket::Article.find( item['o_id'] )
        assets = article.assets(assets)
      end
      if item['history_object'] == 'User'
        user = User.find( item['o_id'] )
        assets = user.assets(assets)
      end
    }

    return {
      :activity_stream => activity_stream,
      :assets          => assets,
    }
  end

  private

  def self.history_type_lookup_id( id )

    # use cache
    return @@cache_type[ id ] if @@cache_type[ id ]

    # lookup
    history_type = History::Type.find(id)
    @@cache_type[ id ] = history_type
    return history_type
  end

  def self.history_type_lookup( name )

    # use cache
    return @@cache_type[ name ] if @@cache_type[ name ]

    # lookup
    history_type = History::Type.where( :name => name ).first
    if history_type
      @@cache_type[ name ] = history_type
      return history_type
    end

    # create
    history_type = History::Type.create(
      :name   => name
    )
    @@cache_type[ name ] = history_type
    return history_type
  end

  def self.history_object_lookup_id( id )

    # use cache
    return @@cache_object[ id ] if @@cache_object[ id ]

    # lookup
    history_object = History::Object.find(id)
    @@cache_object[ id ] = history_object
    return history_object
  end

  def self.history_object_lookup( name )

    # use cache
    return @@cache_object[ name ] if @@cache_object[ name ]

    # lookup
    history_object = History::Object.where( :name => name ).first
    if history_object
      @@cache_object[ name ] = history_object
      return history_object
    end

    # create
    history_object = History::Object.create(
      :name   => name
    )
    @@cache_object[ name ] = history_object
    return history_object
  end

  def self.history_attribute_lookup( name )

    # use cache
    return @@cache_attribute[ name ] if @@cache_attribute[ name ]

    # lookup
    history_attribute = History::Attribute.where( :name => name ).first
    if history_attribute
      @@cache_attribute[ name ] = history_attribute
      return history_attribute
    end

    # create
    history_attribute = History::Attribute.create(
      :name   => name
    )
    @@cache_attribute[ name ] = history_attribute
    return history_attribute
  end

  class Object < ApplicationModel
  end

  class Type < ApplicationModel
  end

  class Attribute < ApplicationModel
  end

end
