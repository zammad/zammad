require 'rss'

class Sessions::Backend::Rss

  def initialize( user, client, client_id, ttl = 30 )
    @user      = user
    @client    = client
    @ttl       = ttl
    @client_id = client_id
  end

  def collection_key
    "rss::load::#{ self.class.to_s }::#{ @user.id }"
  end

  def load

    # check timeout
    cache = Sessions::CacheIn.get( self.collection_key )
    return cache if cache

    url = 'http://www.heise.de/newsticker/heise-atom.xml'
    rss_items = Rss.fetch( url, 8 )

    # set new timeout
    Sessions::CacheIn.set( self.collection_key, rss_items, { expires_in: 1.hours } )

    rss_items
  end

  def client_key
    "rss::load::#{ self.class.to_s }::#{ @user.id }::#{ @client_id }"
  end

  def push

    # check timeout
    timeout = Sessions::CacheIn.get( self.client_key )
    return if timeout

    # set new timeout
    Sessions::CacheIn.set( self.client_key, true, { expires_in: @ttl.seconds } )

    data = self.load

    return if !data || data.empty?

    if !@client
      return {
        event: 'rss_rebuild',
        collection: 'dashboard_rss',
        data: data,
      }
    end

    @client.log 'notify', "push rss for user #{@user.id}"
    @client.send(
      event: 'rss_rebuild',
      collection: 'dashboard_rss',
      data: data,
    )
  end

end
