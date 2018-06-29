class Sessions::Backend::Collections::Base < Sessions::Backend::Base
  class << self; attr_accessor :model, :permissions end

  attr_writer :user

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
    self.class.model.constantize.all.order(id: :asc)
  end

  def client_key
    "collections::load::#{self.class}::#{@user.id}::#{@client_id}"
  end

  def push

    # check timeout
    timeout = Sessions::CacheIn.get(client_key)
    return if timeout

    # set new timeout
    Sessions::CacheIn.set(client_key, true, { expires_in: @ttl.seconds })

    # check permission based access
    if self.class.permissions
      return if !@user.permissions?(self.class.permissions)
    end

    # check if update has been done
    last_change = self.class.model.constantize.latest_change
    return if last_change.to_s == @last_change
    @last_change = last_change.to_s

    # load current data
    items = load

    return if items.blank?

    # get relations of data
    all = []
    items.each do |item|
      all.push item.attributes_with_association_ids
    end

    # collect assets
    assets = {}
    items.each do |item|
      next if !asset_needed?(item)
      assets = asset_push(item, assets)
    end
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

  def self.add_if_permission(key)
    if !@permissions
      @permissions = []
    end
    @permissions.push key
  end

end
