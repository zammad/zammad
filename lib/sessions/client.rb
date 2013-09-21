class Sessions::Client
  def initialize( client_id )
    @client_id = client_id
    @cache_key = ''
    @data = {}
    @pushed = {}
    self.log 'notify', "---client start ws connection---"
    self.fetch
    self.log 'notify', "---client exiting ws connection---"
  end

  def fetch

    loop_count = 0
    while true

      # get connection user
      session_data = Sessions.get( @client_id )
      return if !session_data
      return if !session_data[:user]
      return if !session_data[:user][:id]
      user = User.lookup( :id => session_data[:user][:id] )
      return if !user

      # set cache key
      @cache_key = 'user_' + user.id.to_s

      loop_count += 1
      self.log 'notice', "---client - looking for data of user #{user.id}"

      # remember last run
      Sessions::CacheIn.set( 'last_run_' + user.id.to_s , true, { :expires_in => 20.seconds } )

      # verify already pushed data, send update if needed
      if !Sessions::CacheIn.get( 'pushed_users' + @client_id.to_s )
        Sessions::CacheIn.set( 'pushed_users' + @client_id.to_s , true, { :expires_in => 60.seconds } )
        if @pushed[:users]
          users = {}
          @pushed[:users].each {|user_id, user_o|
            self.user( user_id, users )
          }
          if !users.empty?
            users.each {|user_id, user_data|
              self.log 'notify', "push update of already pushed user id #{user_id}"
            }
            # send update to browser
            self.send({
              :data   => {
                User.to_app_model => users,
              },
              :event => [ 'loadAssets' ],
            });
          end
        end
      end



      # verify already pushed data, send update if needed
      if !Sessions::CacheIn.get( 'pushed_tickets' + @client_id.to_s )
        Sessions::CacheIn.set( 'pushed_tickets' + @client_id.to_s , true, { :expires_in => 60.seconds } )
        if @pushed[:tickets]
          tickets = {}
          users = {}
          @pushed[:tickets].each {|ticket_id, ticket_data|
            self.ticket( ticket_id, tickets, users )
          }
          if !tickets.empty?
            tickets.each {|id, ticket|
              self.log 'notify', "push update of already pushed ticket id #{id}"
            }
            # send update to browser
            self.send({
              :data   => {
                Ticket.to_app_model => tickets,
                User.to_app_model   => users,
              },
              :event => [ 'loadAssets' ],
            });
          end
        end
      end

      # overview
      Sessions::Backend::TicketOverviewIndex.push( user, self )

      # overview_data
      Sessions::Backend::TicketOverviewList.push( user, self )

      # ticket_create_attributes
      Sessions::Backend::TicketCreate.push( user, self )

      # recent viewed
      Sessions::Backend::RecentViewed.push( user, self )

      # activity stream
      Sessions::Backend::ActivityStream.push( user, self )

      # rss
      Sessions::Backend::Rss.push( user, self )

      # push_collections
      Sessions::Backend::Collections.push( user, self )

      self.log 'notice', "---/client-"

      # start faster in the beginnig
      if loop_count < 20
        sleep 0.6
      else
        sleep 1
      end
    end
  end

  # add ticket if needed
  def ticket( ticket_id, tickets, users )
    if !@pushed[:tickets]
      @pushed[:tickets] = {}
    end
    ticket = Ticket.lookup( :id => ticket_id )
    if @pushed[:tickets][ticket_id] != ticket['updated_at']
      @pushed[:tickets][ticket_id] = ticket['updated_at']
      tickets[ticket_id] = ticket
    end

    # add users if needed
    self.user( ticket['owner_id'], users )
    self.user( ticket['customer_id'], users )
    self.user( ticket['created_by_id'], users )
    if ticket['updated_by_id']
      self.user( ticket['updated_by_id'], users )
    end
  end

  # add user if needed
  def user( user_id, users )
    if !@pushed[:users]
      @pushed[:users] = {}
    end

    # get user
    user = User.user_data_full( user_id )

    # user is already on client and not changed
    return if @pushed[:users][ user_id ] == user['updated_at']
    @pushed[:users][user_id] = user['updated_at']

    # user not on client or different
    self.log 'notice', 'push user ... ' + user['login']
    users[ user_id ] = user
  end

  # send update to browser
  def send( data )
    Sessions.send( @client_id, data )
  end

  def log( level, data )
    return if level == 'notice'
    puts "#{Time.now}:client(#{ @client_id }) #{ data }"
  end
end 
