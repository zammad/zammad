class Sessions::Backend::TicketOverviewIndex
  def initialize(user, client = nil, client_id = nil, ttl = 7)
    @user               = user
    @client             = client
    @client_id          = client_id
    @ttl                = ttl
    @last_change        = nil
    @last_ticket_change = nil
  end

  def load

    # get whole collection
    overview = Ticket::Overviews.list(
      current_user: @user,
    )

    # no data exists
    return if !overview

    # no change exists
    return if @last_change == overview

    # remember last state
    @last_change = overview

    overview
  end

  def client_key
    "as::load::#{self.class}::#{@user.id}::#{@client_id}"
  end

  def push

    # check check interval
    return if Sessions::CacheIn.get(client_key)

    # reset check interval
    Sessions::CacheIn.set(client_key, true, { expires_in: @ttl.seconds })

    # check if min one ticket has changed
    last_ticket_change = Ticket.latest_change
    return if last_ticket_change == @last_ticket_change
    @last_ticket_change = last_ticket_change

    # load current data
    data = load

    return if !data

    if !@client
      return {
        event: 'ticket_overview_index',
        data: data,
      }
    end

    @client.log "push overview_index for user #{@user.id}"
    @client.send(
      event: 'ticket_overview_index',
      data: data,
    )
  end

end
