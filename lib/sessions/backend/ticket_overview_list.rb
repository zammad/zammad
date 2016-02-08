class Sessions::Backend::TicketOverviewList
  def initialize( user, client = nil, client_id = nil, ttl = 6 )
    @user               = user
    @client             = client
    @client_id          = client_id
    @ttl                = ttl
    @last_change        = nil
    @last_ticket_change = nil
  end

  def load

    # get whole collection
    overviews = Ticket::Overviews.all(
      current_user: @user,
    )
    return if !overviews
    result = []
    overviews.each { |overview|
      overview_data = Ticket::Overviews.list(
        view: overview.link,
        current_user: @user,
        array: true,
      )
      data = { list: overview_data, index: overview }
      result.push data
    }

    # no data exists
    return if !result || result.empty?

    # no change exists
    return if @last_change == result

    # remember last state
    @last_change = result

    result
  end

  def client_key
    "as::load::#{self.class}::#{@user.id}::#{@client_id}"
  end

  def push

    # check interval
    return if Sessions::CacheIn.get( client_key )

    # reset check interval
    Sessions::CacheIn.set( client_key, true, { expires_in: @ttl.seconds } )

    # check if min one ticket has changed
    last_ticket_change = Ticket.latest_change
    return if last_ticket_change == @last_ticket_change
    @last_ticket_change = last_ticket_change

    # load current data
    items = load
    return if !items

    # push overviews
    results = []
    items.each { |item|

      overview_data = item[:list]

      assets = {}
      overview_data[:ticket_ids].each {|ticket_id|
        ticket = Ticket.find( ticket_id )
        assets = ticket.assets(assets)
      }

      # get groups
      group_ids = []
      Group.where(active: true).each { |group|
        group_ids.push group.id
      }
      agents = {}
      User.of_role('Agent').each { |user|
        agents[ user.id ] = 1
      }
      users = {}
      groups_users = {}
      groups_users[''] = []
      group_ids.each {|group_id|
        groups_users[ group_id ] = []
        Group.find(group_id).users.each {|user|
          next if !agents[ user.id ]
          groups_users[ group_id ].push user.id
          if !users[user.id]
            users[user.id] = User.find(user.id)
            assets = users[user.id].assets(assets)
          end
        }
      }

      if !@client
        result = {
          event: 'navupdate_ticket_overview',
          data: item[:index],
        }
        results.push result
      else

        @client.log "push overview_list for user #{@user.id}"

        # send update to browser
        @client.send(
          data: assets,
          event: 'loadAssets'
        )
        @client.send(
          data: {
            view: item[:index].link.to_s,
            overview: overview_data[:overview],
            ticket_ids: overview_data[:ticket_ids],
            tickets_count: overview_data[:tickets_count],
            bulk: {
              group_id__owner_id: groups_users,
              owner_id: [],
            },
          },
          event: 'ticket_overview_rebuild',
        )
      end
    }
    return results if !@client
    nil
  end

end
