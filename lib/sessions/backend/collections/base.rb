class Sessions::Backend::Collections::Base < Sessions::Backend::Base
  class << self; attr_accessor :model, :roles, :not_roles end

  def initialize(user, asset_lookup, client, client_id, ttl)
    @user         = user
    @client       = client
    @client_id    = client_id
    @ttl          = ttl
    @asset_lookup = asset_lookup
    @last_change  = nil
  end

  def load

    # get whole collection
    self.class.model.constantize.all
  end

  def client_key
    "collections::load::#{self.class}::#{@user.id}::#{@client_id}"
  end

  def push

    # check role based access
    if self.class.roles
      access = false
      self.class.roles.each {|role|
        next if !@user.role?(role)
        access = true
        break
      }
      return if !access
    end
    if self.class.not_roles
      access = false
      self.class.not_roles.each {|role|
        next if @user.role?(role)
        access = true
        break
      }
      return if !access
    end

    # check timeout
    timeout = Sessions::CacheIn.get(client_key)
    return if timeout

    # set new timeout
    Sessions::CacheIn.set(client_key, true, { expires_in: @ttl.seconds })

    # check if update has been done
    last_change = self.class.model.constantize.latest_change
    return if last_change == @last_change
    @last_change = last_change

    # load current data
    items = load

    return if !items || items.empty?

    # get relations of data
    all = []
    items.each {|item|
      all.push item.attributes_with_associations
    }

    # collect assets
    assets = {}
    items.each {|item|
      next if !asset_needed?(item)
      assets = item.assets(assets)
    }
    if !@client
      return {
        collection: {
          items.first.class.to_app_model => all,
        },
        assets: assets,
      }
    end
    @client.log "push assets for push_collection #{items.first.class} for user #{@user.id}"
    @client.send(
      data: assets,
      event: 'loadAssets',
    )

    @client.log "push push_collection #{items.first.class} for user #{@user.id}"
    @client.send(
      event: 'resetCollection',
      data: {
        items.first.class.to_app_model => all,
      },
    )
  end

  def self.model_set(model)
    @model = model
  end

  def self.add_if_role(role)
    if !@roles
      @roles = []
    end
    @roles.push role
  end

  def self.add_if_not_role(role)
    if !@not_roles
      @not_roles = []
    end
    @not_roles.push role
  end

end
