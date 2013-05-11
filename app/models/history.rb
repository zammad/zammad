class History < ApplicationModel
  self.table_name = 'histories'
  belongs_to :history_type,             :class_name => 'History::Type'
  belongs_to :history_object,           :class_name => 'History::Object'
  belongs_to :history_attribute,        :class_name => 'History::Attribute'
#  before_validation :check_type, :check_object
#  attr_writer :history_type, :history_object

  @@cache_type = {}
  @@cache_object = {}
  @@cache_attribute = {}

  def self.history_create(data) 

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
      record_new.id = record[:id]
      record_new.save
    end
  end

  def self.history_destroy( requested_object, requested_object_id )
    History.where( :history_object_id => History::Object.where( :name => requested_object ) ).
      where( :o_id => requested_object_id ).
      destroy_all
  end

  def self.history_list( requested_object, requested_object_id, related_history_object = nil )
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

    list = []
    history.each { |item|
      item_tmp = item.attributes
      item_tmp['history_type'] = item.history_type.name
      item_tmp['history_object'] = item.history_object.name
      if item.history_attribute
       item_tmp['history_attribute'] = item.history_attribute.name
      end
      item_tmp.delete( 'history_attribute_id' )
      item_tmp.delete( 'history_object_id' )
      item_tmp.delete( 'history_type_id' )
      item_tmp.delete( 'o_id' )
      item_tmp.delete( 'updated_at' )
      if item_tmp['id_to'] == nil && item_tmp['id_from'] == nil
        item_tmp.delete( 'id_to' )
        item_tmp.delete( 'id_from' )
      end
      if item_tmp['value_to'] == nil && item_tmp['value_from'] == nil
        item_tmp.delete( 'value_to' )
        item_tmp.delete( 'value_from' )
      end
      if item_tmp['related_history_object_id'] == nil
        item_tmp.delete( 'related_history_object_id' )
      end
      if item_tmp['related_o_id'] == nil
        item_tmp.delete( 'related_o_id' )
      end
      list.push item_tmp
    }
    return list
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
    users = {}
    tickets = []
    articles = []
    activity_stream.each {|item|

      # load article ids
      if item['history_object'] == 'Ticket'
        ticket = Ticket.find( item['o_id'] ).attributes
        tickets.push ticket

        # load users
        if !users[ ticket['owner_id'] ]
          users[ ticket['owner_id'] ] = User.user_data_full( ticket['owner_id'] )
        end
        if !users[ ticket['customer_id'] ]
          users[ ticket['customer_id'] ] = User.user_data_full( ticket['customer_id'] )
        end
      end
      if item['history_object'] == 'Ticket::Article'
        article = Ticket::Article.find( item['o_id'] ).attributes
        if !article['subject'] || article['subject'] == ''
          article['subject'] = Ticket.find( article['ticket_id'] ).title
        end
        articles.push article

        # load users
        if !users[ article['created_by_id'] ]
          users[ article['created_by_id'] ] = User.user_data_full( article['created_by_id'] )
        end
      end
      if item['history_object'] == 'User'
        users[ item['o_id'] ] = User.user_data_full( item['o_id'] )
      end
          
      # load users
      if !users[ item['created_by_id'] ]
        users[ item['created_by_id'] ] = User.user_data_full( item['created_by_id'] )
      end
    }

    return {
      :activity_stream => activity_stream,
      :tickets         => tickets,
      :articles        => articles,
      :users           => users,
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
