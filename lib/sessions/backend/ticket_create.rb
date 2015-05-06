class Sessions::Backend::TicketCreate
  def initialize( user, client = nil, client_id = nil, ttl = 30 )
    @user        = user
    @client      = client
    @client_id   = client_id
    @ttl         = ttl
    @last_change = nil
  end

  def load

    # get attributes to update
    ticket_create_attributes = Ticket::ScreenOptions.attributes_to_change(
      user: @user.id,
    )

    # no data exists
    return if !ticket_create_attributes

    # no change exists
    return if @last_change == ticket_create_attributes

    # remember last state
    @last_change = ticket_create_attributes

    ticket_create_attributes
  end

  def client_key
    "as::load::#{ self.class }::#{ @user.id }::#{ @client_id }"
  end

  def push

    # check timeout
    timeout = Sessions::CacheIn.get( self.client_key )
    return if timeout

    # set new timeout
    Sessions::CacheIn.set( self.client_key, true, { expires_in: @ttl.seconds } )

    ticket_create_attributes = self.load

    return if !ticket_create_attributes

    data = {
      assets: ticket_create_attributes[:assets],
      form_meta: {
        filter: ticket_create_attributes[:filter],
        dependencies: ticket_create_attributes[:dependencies],
      }
    }

    if !@client
      return {
        collection: 'ticket_create_attributes',
        data: data,
      }
    end

    @client.log "push ticket_create for user #{ @user.id }"
    @client.send(
      collection: 'ticket_create_attributes',
      data: data,
    )
  end

end
