module Sessions::Backend::TicketOverviewList
  @@last_change = {}

  def self.worker( user, worker )
    overviews = Ticket::Overviews.all(
      :current_user => user,
    )
    overviews.each { |overview|
      cache_key = 'user_' + user.id.to_s + '_overview_data_' + overview.link
      if Sessions::CacheIn.expired(cache_key)
        overview_data = Ticket::Overviews.list(
          :view         => overview.link,
          :current_user => user,
          :array        => true,
        )
        overview_data_cache = Sessions::CacheIn.get( cache_key, { :re_expire => true } )
        worker.log 'notice', 'fetch overview_data - ' + cache_key
        if overview_data != overview_data_cache
          worker.log 'notify', 'fetch overview_data changed - ' + cache_key
          Sessions::CacheIn.set( cache_key, overview_data, { :expires_in => 5.seconds } )
        end
      end
    }
  end

  def self.push( user, client )
    overviews = Ticket::Overviews.all(
      :current_user => user,
    )
    overviews.each { |overview|
      cache_key = 'user_' + user.id.to_s + '_overview_data_' + overview.link

      if !@@last_change[ user.id ]
        @@last_change[ user.id ] = {}
      end

      overview_data_time = Sessions::CacheIn.get_time( cache_key, { :ignore_expire => true } )
      if overview_data_time && @@last_change[ user.id ][overview.link] != overview_data_time
        @@last_change[ user.id ][overview.link] = overview_data_time
        overview_data = Sessions::CacheIn.get( cache_key, { :ignore_expire => true } )
        client.log 'notify', "push overview_data #{overview.link} for user #{user.id}"
        users = {}
        tickets = {}
        overview_data[:ticket_ids].each {|ticket_id|
          client.ticket( ticket_id, tickets, users )
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
        groups_users = {}
        groups_users[''] = []
        group_ids.each {|group_id|
            groups_users[ group_id ] = []
            Group.find(group_id).users.each {|user|
                next if !agents[ user.id ]
                groups_users[ group_id ].push user.id
                if !users[user.id]
                  users[user.id] = User.user_data_full(user.id)
                end
            }
        }

        # send update to browser
        client.send({
          :data => {
            User.to_online_model.to_sym    => users,
            Ticket.to_online_model.to_sym  => tickets,
          },
          :event => [ 'loadAssets' ]
        })
        client.send({
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
      end
    }
  end

end 
