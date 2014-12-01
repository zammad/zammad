class Sessions::Backend::Collections::Base
  class << self; attr_accessor :model, :is_role, :is_not_role end

  def initialize( user, client = nil, client_id = nil )
    @user         = user
    @client       = client
    @client_id    = client_id
    @last_change  = nil
  end

  def collection_key
    "collections::load::#{ self.class.to_s }::#{ @user.id }"
  end

  def load
#puts "-LOAD--------#{self.collection_key}"
    # check timeout
    cache = Sessions::CacheIn.get( self.collection_key )
    return cache if @last_change && cache
#puts "---REAL FETCH #{@user.id}"
    # update last changed
    last = self.class.model.constantize.select('updated_at').order('updated_at DESC').first
    if last
      @last_change = last.updated_at
    end

    # if no entry exists, remember last check
    if !@last_change
      @last_change = Time.now
    end

    # get whole collection
    all = self.class.model.constantize.all

    # set new timeout
    Sessions::CacheIn.set( self.collection_key, all, { :expires_in => 10.minutes } )

    all
  end

  def changed?
    # if no data has been delivered till now
    return true if !@last_change

    # check if update has been done
    last = self.class.model.constantize.select('updated_at').order('updated_at DESC').first
    return false if !last
    return false if last.updated_at == @last_change

    # delete collection cache
    Sessions::CacheIn.delete( self.collection_key )

    # collection has changed
    true
  end

  def client_key
    "collections::load::#{ self.class.to_s }::#{ @user.id }::#{ @client_id }"
  end

  def push

    # check role based access
    if self.class.is_role
      access = nil
      self.class.is_role.each {|role|
        if @user.is_role(role)
          access = true
        end
      }
      return if !access
    end
    if self.class.is_not_role
      self.class.is_not_role.each {|role|
        return if @user.is_role(role)
      }
    end

    # check timeout
    timeout = Sessions::CacheIn.get( self.client_key )
    return if timeout

    # set new timeout
    Sessions::CacheIn.set( self.client_key, true, { :expires_in => 10.seconds } )

    return if !self.changed?
    items = self.load

    return if !items||items.empty?

    # get relations of data
    all   = []
    items.each {|item|
      all.push item.attributes_with_associations
    }

    # collect assets
    assets = {}
    items.each {|item|
      assets = item.assets(assets)
    }
    if !@client
      return {
        :collection => {
          items.first.class.to_app_model => all,
        },
        :assets => assets,
      }
    end
    @client.log 'notify', "push assets for push_collection #{ items.first.class.to_s } for user #{ @user.id }"
    @client.send({
      :data   => assets,
      :event  => [ 'loadAssets' ],
    })

    @client.log 'notify', "push push_collection #{ items.first.class.to_s } for user #{ @user.id }"
    @client.send({
      :event  => 'resetCollection',
      :data   => {
        items.first.class.to_app_model => all,
      },
    })
  end

  def self.model_set(model)
    @model = model
  end

  def self.is_role_set(role)
    if !@is_role
      @is_role = []
    end
    @is_role.push role
  end

  def self.is_not_role_set(role)
    if !@is_not_role
      @is_not_role = []
    end
    @is_not_role.push role
  end

end