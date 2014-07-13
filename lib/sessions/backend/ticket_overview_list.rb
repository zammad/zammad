class Sessions::Backend::TicketOverviewList
  def initialize( user, client = nil, client_id = nil )
    @user         = user
    @client       = client
    @client_id    = client_id
    @last_change  = nil
  end

  def load

    # get whole collection
    overviews = Ticket::Overviews.all(
      :current_user => @user,
    )

    # no data exists
    return if !overviews

    # no change exists
    return if @last_change == overviews

    # remember last state
    @last_change = overviews

    overviews
  end

  def client_key
    "as::load::#{ self.class.to_s }::#{ @user.id }::#{ @client_id }"
  end

  def push

    # check timeout
    timeout = Sessions::CacheIn.get( self.client_key )
    return if timeout

    # set new timeout
    Sessions::CacheIn.set( self.client_key, true, { :expires_in => 5.seconds } )

    overviews = self.load

    return if !overviews

    # push overviews
    overviews.each { |overview|

      overview_data = Ticket::Overviews.list(
        :view         => overview.link,
        :current_user => @user,
        :array        => true,
      )

      assets = {}
      overview_data[:ticket_ids].each {|ticket_id|
        ticket = Ticket.find( ticket_id )
        assets = ticket.assets(assets)
      }

      # get groups
      group_ids = []
      Group.where( :active => true ).each { |group|
        group_ids.push group.id
      }
      agents = {}
      Ticket::ScreenOptions.agents.each { |user|
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
        return {
          :event  => 'navupdate_ticket_overview',
          :data   => overview,
        }
      end

      @client.log 'notify', "push overview_list for user #{ @user.id }"

      # send update to browser
      @client.send({
        :data   => assets,
        :event  => [ 'loadAssets' ]
      })
      @client.send({
        :data   => {
          :overview      => overview_data[:overview],
          :ticket_ids    => overview_data[:ticket_ids],
          :tickets_count => overview_data[:tickets_count],
          :bulk => {
            :group_id__owner_id => groups_users,
            :owner_id           => [],
          },
        },
        :event      => [ 'ticket_overview_rebuild' ],
        :collection => 'ticket_overview_' + overview.link.to_s,
      })
    }
  end

end