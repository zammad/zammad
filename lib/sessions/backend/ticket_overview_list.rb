class Sessions::Backend::TicketOverviewList

  def self.reset(user_id)
    key = "TicketOverviewPull::#{user_id}"
    Cache.write(key, { needed: true })
  end

  def initialize(user, client = nil, client_id = nil, ttl = 8)
    @user                 = user
    @client               = client
    @client_id            = client_id
    @ttl                  = ttl
    @last_change          = nil
    @last_overview        = {}
    @last_overview_change = nil
    @last_ticket_change   = nil
  end

  def load

    # get whole collection
    index_and_lists = Ticket::Overviews.index(@user)

    # no data exists
    return if !index_and_lists || index_and_lists.empty?

    # no change exists
    return if @last_change == index_and_lists

    # remember last state
    @last_change = index_and_lists

    index_and_lists
  end

  def client_key
    "as::load::#{self.class}::#{@user.id}::#{@client_id}"
  end

  def work_needed?
    key = "TicketOverviewPull::#{@user.id}"
    if Cache.get(key)
      Cache.delete(key)
      return true
    end
    return false if Sessions::CacheIn.get(client_key)
    true
  end

  def push

    return if !work_needed?

    # reset check interval
    Sessions::CacheIn.set(client_key, true, { expires_in: @ttl.seconds })

    # check if min one ticket or overview has changed
    last_overview_change = Overview.latest_change
    last_ticket_change = Ticket.latest_change
    return if last_ticket_change == @last_ticket_change && last_overview_change == @last_overview_change
    @last_overview_change = last_overview_change
    @last_ticket_change = last_ticket_change

    # load current data
    index_and_lists = load
    return if !index_and_lists

    # push overview index
    indexes = []
    index_and_lists.each { |index|
      assets = {}
      overview = Overview.lookup(id: index[:overview][:id])
      meta = {
        name: overview.name,
        prio: overview.prio,
        link: overview.link,
        count: index[:count],
      }
      indexes.push meta
    }
    if @client
      @client.log "push overview_index for user #{@user.id}"
      @client.send(
        event: 'ticket_overview_index',
        data: indexes,
      )
    end

    # push overviews
    results = []
    index_and_lists.each { |index|

      # do not deliver unchanged lists
      next if @last_overview[index[:overview][:id]] == index
      @last_overview[index[:overview][:id]] = index

      assets = {}
      overview = Overview.lookup(id: index[:overview][:id])
      assets = overview.assets(assets)
      index[:tickets].each {|ticket_meta|
        ticket = Ticket.lookup(id: ticket_meta[:id])
        assets = ticket.assets(assets)
      }

      if !@client
        result = {
          event: 'ticket_overview_list',
          data: index,
        }
        results.push result
      else

        @client.log "push overview_list #{overview.link} for user #{@user.id}"

        # send update to browser
        @client.send(
          event: 'loadAssets',
          data: assets,
        )
        @client.send(
          event: 'ticket_overview_list',
          data: index,
        )
      end
    }
    return results if !@client
    nil
  end

end
