require 'rss'

class Sessions::Backend::Rss

  def initialize(user, client, client_id, ttl = 30)
    @user      = user
    @client    = client
    @ttl       = ttl
    @client_id = client_id
  end

  def collection_key
    "rss::load::#{self.class}::#{@user.id}"
  end

  def load

    # check timeout
    cache = Sessions::CacheIn.get(collection_key)
    return cache if cache

    url = 'http://www.heise.de/newsticker/heise-atom.xml'
    rss_items = Rss.fetch(url, 8)

    # set new timeout
    Sessions::CacheIn.set(collection_key, rss_items, { expires_in: 1.hour })

    rss_items
  end

  def client_key
    "rss::load::#{self.class}::#{@user.id}::#{@client_id}"
  end

  def push

    # check timeout
    timeout = Sessions::CacheIn.get(client_key)
    return if timeout

    # set new timeout
    Sessions::CacheIn.set(client_key, true, { expires_in: @ttl.seconds })

    data = load

    return if !data || data.empty?

    if !@client
      return {
        event: 'rss_rebuild',
        collection: 'dashboard_rss',
        data: data,
      }
    end

    @client.log "push rss for user #{@user.id}"
    @client.send(
      event: 'rss_rebuild',
      collection: 'dashboard_rss',
      data: data,
    )
  end

end
