# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class OnlineNotification < ApplicationModel
  belongs_to :type_lookup,     :class_name => 'TypeLookup'
  belongs_to :object_lookup,   :class_name => 'ObjectLookup'

  after_create    :notify_clients_after_change
  after_update    :notify_clients_after_change
  after_destroy   :notify_clients_after_change

=begin

add a new online notification for this user

  OnlineNotification.add(
    :type             => 'Assigned to you',
    :object           => 'Ticket',
    :o_id             => ticket.id,
    :seen             => false,
    :created_by_id    => 1,
    :user_id          => 2,
  )

=end

  def self.add(data)

    # lookups
    if data[:type]
      type_id = TypeLookup.by_name( data[:type] )
    end
    if data[:object]
      object_id = ObjectLookup.by_name( data[:object] )
    end

    record = {
      :o_id               => data[:o_id],
      :object_lookup_id   => object_id,
      :type_lookup_id     => type_id,
      :seen               => data[:seen],
      :user_id            => data[:user_id],
      :created_by_id      => data[:created_by_id]
    }

    OnlineNotification.create(record)
  end

=begin

add a new online notification for this user

  OnlineNotification.add(
    :type             => 'Assigned to you',
    :object           => 'Ticket',
    :o_id             => ticket.id,
    :seen             => 1,
    :created_by_id    => 1,
    :user_id          => 2,
  )

=end

  def self.seen(data)
    notification = OnlineNotification.find(data[:id])
    notification.seen = true
    notification.save
  end

=begin

remove whole online notifications of an object

  OnlineNotification.remove( 'Ticket', 123 )

=end

  def self.remove( object_name, o_id )
    object_id = ObjectLookup.by_name( object_name )
    OnlineNotification.where(
      :object_lookup_id  => object_id,
      :o_id              => o_id,
    ).destroy_all
  end

=begin

return all online notifications of an user

  notifications = OnlineNotification.list( user )

=end

  def self.list(user,limit)

    notifications = OnlineNotification.where(:user_id => user.id).
      order( 'created_at DESC, id DESC' ).
      limit( limit )
    list = []
    notifications.each do |item|
      data = item.attributes
      data['object']  = ObjectLookup.by_id( data['object_lookup_id'] )
      data['type']    = TypeLookup.by_id( data['type_lookup_id'] )
      data.delete('object_lookup_id')
      data.delete('type_lookup_id')
      list.push data
    end
    list
  end

=begin

return all online notifications of an user with assets

  OnlineNotification.list_full( user )

returns:

  list = {
    :stream => notifications,
    :assets => assets
  }

=end

  def self.list_full(user,limit)

    notifications = OnlineNotification.list(user, limit)
    assets = ApplicationModel.assets_of_object_list(notifications)
    return {
      :stream => notifications,
      :assets => assets
    }
  end

  def notify_clients_after_change

    puts "#{ self.class.name } changed " + self.created_at.to_s
    Sessions.broadcast(
      :event => 'OnlineNotification::changed',
      :data => {}
    )
  end

end