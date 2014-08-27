# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class RecentView < ApplicationModel
  belongs_to :object_lookup,           :class_name => 'ObjectLookup'

  after_create    :notify_clients
  after_update    :notify_clients
  after_destroy   :notify_clients

  def self.log( object, o_id, user )

    # lookups
    object_lookup_id = ObjectLookup.by_name( object )

    # create entry
    record = {
      :o_id                   => o_id,
      :recent_view_object_id  => object_lookup_id.to_i,
      :created_by_id          => user.id,
    }
    RecentView.create(record)
  end

  def self.log_destroy( requested_object, requested_object_id )
    return if requested_object == 'RecentView'
    RecentView.where( :recent_view_object_id => ObjectLookup.by_name( requested_object ) ).
      where( :o_id => requested_object_id ).
      destroy_all
  end

  def self.user_log_destroy( user )
    RecentView.where( :created_by_id => user.id ).destroy_all
  end

  def self.list( user, limit = 10 )
    recent_views = RecentView.where( :created_by_id => user.id ).
    order('created_at DESC, id DESC').
    limit(limit)

    list = []
    recent_views.each { |item|
      data = item.attributes
      data['object'] = ObjectLookup.by_id( data['recent_view_object_id'] )
      data.delete( 'recent_view_object_id' )
      list.push data
    }
    list
  end

  def self.list_full( user, limit = 10 )
    recent_viewed = self.list( user, limit )

    # get related object
    assets = ApplicationModel.assets_of_object_list(recent_viewed)

    return {
      :stream => recent_viewed,
      :assets => assets,
    }
  end

  def notify_clients
    data = RecentView.list_full( User.find(self.created_by_id), 10 )
    Sessions.send_to(
      self.created_by_id,
      {
        :event      => 'update_recent_viewed',
        :data       => data,
      }
    )
  end

  class Object < ApplicationModel
  end
end