class Sessions::Backend::TicketCreate
  def initialize( user, client = nil, client_id = nil )
    @user         = user
    @client       = client
    @client_id    = client_id
    @last_change  = nil
  end

  def load

    # get whole collection
    ticket_create_attributes = Ticket::ScreenOptions.attributes_to_change(
      :current_user_id => @user.id,
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
    "as::load::#{ self.class.to_s }::#{ @user.id }::#{ @client_id }"
  end

  def push

    # check timeout
    timeout = Sessions::CacheIn.get( self.client_key )
    return if timeout

    # set new timeout
    Sessions::CacheIn.set( self.client_key, true, { :expires_in => 25.seconds } )

    create_attributes = self.load

    return if !create_attributes

    users = {}
    create_attributes[:owner_id].each {|user_id|
      if !users[user_id]
        users[user_id] = User.find(user_id).attributes
      end
    }
    data = {
      :users     => users,
      :edit_form => create_attributes,
    }

    if !@client
      return {
        :collection => 'ticket_create_attributes',
        :data       => create_attributes,
      }
    end

    @client.log 'notify', "push ticket_create for user #{ @user.id }"
    @client.send({
      :collection => 'ticket_create_attributes',
      :data       => create_attributes,
    })
  end

end