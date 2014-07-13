class Sessions::Backend::RecentViewed

  def initialize( user, client = nil, client_id = nil )
    @user         = user
    @client       = client
    @client_id    = client_id
    @last_change  = nil
  end

  def load

    # get whole collection
    recent_viewed = RecentView.list( @user, 10 )

    # no data exists
    return if !recent_viewed
    return if recent_viewed.empty?

    # no change exists
    return if @last_change == recent_viewed

    # remember last state
    @last_change = recent_viewed

    RecentView.list_fulldata( @user, 10 )
  end

  def client_key
    "as::load::#{ self.class.to_s }::#{ @user.id }::#{ @client_id }"
  end

  def push

    # check timeout
    timeout = Sessions::CacheIn.get( self.client_key )
    return if timeout

    # set new timeout
    Sessions::CacheIn.set( self.client_key, true, { :expires_in => 15.seconds } )

    data = self.load

    return if !data||data.empty?

    if !@client
      return {
        :event      => 'update_recent_viewed',
        :data       => data,
      }
    end

    @client.log 'notify', "push recent_viewed for user #{ @user.id }"
    @client.send({
      :event      => 'update_recent_viewed',
      :data       => data,
    })
  end

end