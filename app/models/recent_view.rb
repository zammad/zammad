class RecentView < ApplicationModel
  belongs_to :recent_view_object,           :class_name => 'RecentView::Object'

  @@cache_object = {}

  def self.log( object, user ) 

    # lookups
    recent_view_object = self.recent_view_object_lookup( object.class.to_s )

    # create entry
    record = {
      :o_id                   => object.id,
      :recent_view_object_id  => recent_view_object.id,
      :created_by_id          => user.id,
    }
    RecentView.create(record)
  end

  def self.log_destroy( requested_object, requested_object_id )
    RecentView.where( :recent_view_object_id => RecentView::Object.where( :name => requested_object ) ).
      where( :o_id => requested_object_id ).
      destroy_all
  end

  def self.list( user, limit = 10 )
    recent_views = RecentView.where( :created_by_id => user.id ).
      order('created_at DESC, id DESC').
      limit(limit)

    list = []
    recent_views.each { |item|
      data = item.attributes
      data['recent_view_object'] = self.recent_view_object_lookup_id( data['recent_view_object_id'] ).name
      data.delete( 'history_object_id' )
      list.push data
    }
    return list
  end

  def self.list_fulldata( user, limit = 10 )
    recent_viewed = self.list( user, limit )

    # get related users
    users = {}
    tickets = []
    recent_viewed.each {|item|

      # load article ids
#      if item.recent_view_object == 'Ticket'
        ticket = Ticket.find( item['o_id'] ).attributes
        tickets.push ticket
#      end
#      if item.recent_view_object 'Ticket::Article'
#        tickets.push Ticket::Article.find(item.o_id)
#      end
#      if item.recent_view_object 'User'
#        tickets.push User.find(item.o_id)
#      end
          
      # load users
      if !users[ ticket['owner_id'] ]
        users[ ticket['owner_id'] ] = User.user_data_full( ticket['owner_id'] )
      end
      if !users[ ticket['created_by_id'] ]
        users[ ticket['created_by_id'] ] = User.user_data_full( ticket['created_by_id'] )
      end
      if !users[ item['created_by_id'] ]
        users[ item['created_by_id'] ] = User.user_data_full( item['created_by_id'] )
      end
    }
    return {
      :recent_viewed => recent_viewed,
      :tickets       => tickets,
      :users         => users,
    }
  end

  private

    def self.recent_view_object_lookup_id( id ) 

      # use cache
      return @@cache_object[ id ] if @@cache_object[ id ]

      # lookup
      history_object = RecentView::Object.find(id)
      @@cache_object[ id ] = history_object
      return history_object
    end

    def self.recent_view_object_lookup( name ) 

      # use cache
      return @@cache_object[ name ] if @@cache_object[ name ]

      # lookup
      recent_view_object = RecentView::Object.where( :name => name ).first
      if recent_view_object
        @@cache_object[ name ] = recent_view_object
        return recent_view_object
      end

      # create
      recent_view_object = RecentView::Object.create(
        :name => name
      )
      @@cache_object[ name ] = recent_view_object
      return recent_view_object
    end

  class Object < ApplicationModel
  end

end
