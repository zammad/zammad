class Sessions::Backend::Collections::Base
  class << self; attr_accessor :model, :is_role, :is_not_role end

  def initialize( user, client = nil, client_id = nil, ttl )
    @user        = user
    @client      = client
    @client_id   = client_id
    @ttl         = ttl
    @last_change = nil
  end

  def load

    # get whole collection
    self.class.model.constantize.all
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
    Sessions::CacheIn.set( self.client_key, true, { :expires_in => @ttl.seconds } )

    # check if update has been done
    last_change = self.class.model.constantize.latest_change
    return if last_change == @last_change
    @last_change = last_change

    # load current data
    items = self.load

    return if !items||items.empty?

    # get relations of data
    all = []
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