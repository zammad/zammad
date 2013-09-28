# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

class ActivityStream < ApplicationModel
  self.table_name = 'activity_streams'
  belongs_to :activity_stream_type,     :class_name => 'ActivityStream::Type'
  belongs_to :activity_stream_object,   :class_name => 'ActivityStream::Object'

  @@cache_type = {}
  @@cache_object = {}

=begin

add a new activity entry for an object

  ActivityStream.add(
    :type             => 'updated',
    :object           => 'Ticket',
    :role             => 'Admin',
    :o_id             => ticket.id,
    :created_by_id    => 1,
    :created_at       => '2013-06-04 10:00:00',
  )

=end

  def self.add(data)

    # lookups
    if data[:type]
      type = self.type_lookup( data[:type] )
    end
    if data[:object]
      object = self.object_lookup( data[:object] )
    end

    role_id = nil
    if data[:role]
      role_id = Role.lookup( :name => data[:role] )
      if !role_id
        raise "No such Role #{data[:role]}"
      end
    end

    # check if entry is needed
    result = ActivityStream.where(
      :o_id                        => data[:o_id],
 #     :activity_stream_type_id     => type.id,
      :role_id                     => role_id,
      :activity_stream_object_id   => object.id,
      :created_by_id               => data[:created_by_id]      
    ).last

    # resturn if old entry is really freash
    return result if result && result.created_at >= (data[:created_at] - 10.seconds)
    puts "AS: #{data[:type]} #{data[:object]} #{data[:o_id]}"

    # create history
    record = {
      :o_id                        => data[:o_id],
      :activity_stream_type_id     => type.id,
      :activity_stream_object_id   => object.id,
      :created_at                  => data[:created_at],
      :created_by_id               => data[:created_by_id]
    }
    ActivityStream.create(record)
  end

=begin

remove whole activity entries of an object

  ActivityStream.remove( 'Ticket', 123 )

=end

  def self.remove( object_name, o_id )
    object = self.object_lookup( object_name )
    ActivityStream.where(
      :activity_stream_object_id  => object.id,
      :o_id                       => o_id,
    ).destroy_all
  end

=begin

return all activity entries of an user

  activity_stream = ActivityStream.list( user )

=end

  def self.list(user,limit)
#    stream = ActivityStream.where( :role_id => user.roles, :group_id => user.groups )
    stream = ActivityStream.where('1=1').
    order( 'created_at DESC, id DESC' ).
    limit( limit )
    list = []
    stream.each do |item|
      data = item.attributes
      data['object']  = self.object_lookup_id( data['activity_stream_object_id'] ).name
      data['type']    = self.type_lookup_id( data['activity_stream_type_id'] ).name
      data.delete('activity_stream_object_id')
      data.delete('activity_stream_type_id')
      list.push data
    end
    list
  end

  private

  def self.type_lookup_id( id )

    # use cache
    return @@cache_type[ id ] if @@cache_type[ id ]

    # lookup
    type = ActivityStream::Type.find(id)
    @@cache_type[ id ] = type
    type
  end

  def self.type_lookup( name )

    # use cache
    return @@cache_type[ name ] if @@cache_type[ name ]

    # lookup
    type = ActivityStream::Type.where( :name => name ).first
    if type
      @@cache_type[ name ] = type
      return type
    end

    # create
    type = ActivityStream::Type.create(
      :name   => name
    )
    @@cache_type[ name ] = type
    type
  end

  def self.object_lookup_id( id )

    # use cache
    return @@cache_object[ id ] if @@cache_object[ id ]

    # lookup
    object = ActivityStream::Object.find(id)
    @@cache_object[ id ] = object
    object
  end

  def self.object_lookup( name )

    # use cache
    return @@cache_object[ name ] if @@cache_object[ name ]

    # lookup
    object = ActivityStream::Object.where( :name => name ).first
    if object
      @@cache_object[ name ] = object
      return object
    end

    # create
    object = ActivityStream::Object.create(
      :name   => name
    )
    @@cache_object[ name ] = object
    object
  end

  class Object < ApplicationModel
  end

  class Type < ApplicationModel
  end

end
