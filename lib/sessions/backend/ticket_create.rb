class Sessions::Backend::TicketCreate < Sessions::Backend::Base

  def load
    # get attributes to update
    ticket_create_attributes = Ticket::ScreenOptions.attributes_to_change(
      current_user: @user,
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
    "as::load::#{self.class}::#{@user.id}::#{@client_id}"
  end

  def push

    # check timeout
    timeout = Sessions::CacheIn.get(client_key)
    return if timeout

    # set new timeout
    Sessions::CacheIn.set(client_key, true, { expires_in: @ttl.seconds })

    data = load

    return if !data

    if !@client
      return {
        event: 'ticket_create_attributes',
        data: data,
      }
    end

    @client.log "push ticket_create for user #{@user.id}"
    @client.send(
      event: 'ticket_create_attributes',
      data: data,
    )
  end

end
