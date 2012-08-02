require 'json'

module Session
  @path = '/tmp/websocket'

  def self.create( client_id, session )
    path = @path + '/' + client_id.to_s
    FileUtils.mkpath path
    File.open( path + '/session', 'w' ) { |file|
      user = { :id => session['id'] }  
      file.puts Marshal.dump(user)
    }
  end

  def self.get( client_id )
    session_file = @path + '/' + client_id.to_s + '/session'
    data = nil
    return if !File.exist? session_file
    File.open( session_file, 'r' ) { |file|
      all = ''
      while line = file.gets  
        all = all + line  
      end
      begin  
        data = Marshal.load( all )
      rescue
        return
      end
    }
    return data
  end

  def self.transaction( client_id, data )
    filename = @path + '/' + client_id.to_s + '/transaction-' + Time.new().to_i.to_s
    if File::exists?( filename )
      filename = @path + '/' + client_id.to_s + '/transaction-' + Time.new().to_i.to_s + '-1'
      if File::exists?( filename )
        filename = @path + '/' + client_id.to_s + '/transaction-' + Time.new().to_i.to_s + '-2'
        if File::exists?( filename )
          filename = @path + '/' + client_id.to_s + '/transaction-' + Time.new().to_i.to_s + '-3'
          if File::exists?( filename )
            filename = @path + '/' + client_id.to_s + '/transaction-' + Time.new().to_i.to_s + '-4'
          end
        end
      end
    end
    File.open( filename, 'w' ) { |file|
      file.puts data.to_json
    }
    return true
  end

  def self.jobs
    state_client_ids = {}
    state_user_ids = {}
    while true
      client_ids = self.sessions
      client_ids.each { |client_id|

        if !state_client_ids[client_id]
          state_client_ids[client_id] = {}
        end

        # get current user  
        user_session = Session.get( client_id )
        next if !user_session
        next if !user_session[:id]
        user = User.find( user_session[:id] )

        if !state_user_ids[ user.id ]
            state_user_ids[ user.id ] = {}
        end

        # check user cache
        if self.jobs_user_needed( state_user_ids[ user.id ], :overview, 1.seconds )
          puts "fetch for user_id #{ user.id } :overview..."
          # overview meta data
          overview = Ticket.overview(
            :current_user_id => user.id,
          )
          self.jobs_user_data_set( state_user_ids[ user.id ], :overview, overview )
        else
          puts "use user_id #{ user.id } cache for :overview..."
          overview = self.jobs_user_data_get( state_user_ids[ user.id ], :overview )
        end

        if state_client_ids[client_id][:overview] != overview
          state_client_ids[client_id][:overview] = overview

          # send update to browser  
          Session.transaction( client_id, {
            :data   => overview,
            :event  => 'navupdate_ticket_overview',
          })
        end

        # ticket overview lists
        overviews = Ticket.overview_list(
          :current_user_id => user.id,
        )
        if !state_client_ids[client_id][:overview_data]
          state_client_ids[client_id][:overview_data] = {}
        end
        overviews.each { |overview|

          # check user cache
          cache_key = ( 'overview_data_' + overview.meta[:url] ).to_sym
          if self.jobs_user_needed( state_user_ids[ user.id ], cache_key, 1.seconds )
            puts "fetch for user_id #{ user.id } #{ cache_key.to_s }..."
              overview_data = Ticket.overview(
                :view            => overview.meta[:url],
    #            :view_mode       => params[:view_mode],
                :current_user_id => user.id,
                :array           => true,
              )
              self.jobs_user_data_set( state_user_ids[ user.id ], cache_key, overview_data )
          else
            puts "use user_id #{ user.id } cache for #{ cache_key.to_s }..."
            overview_data = self.jobs_user_data_get( state_user_ids[ user.id ], cache_key )
          end

          if state_client_ids[client_id][ cache_key ] != overview_data
            state_client_ids[client_id][ cache_key ] = overview_data
puts 'push overview ' + overview.meta[:url].to_s
            users = {}
            tickets = []
            ticket_list = []
            overview_data[:tickets].each {|ticket|
              ticket_list.push ticket.id
              self.jobs_ticket( ticket.id, state_client_ids[client_id], tickets, users )
            }

            # send update to browser  
            Session.transaction( client_id, {
              :data   => {
                :overview      => overview_data[:overview],
                :ticket_list   => ticket_list,
                :tickets_count => overview_data[:tickets_count],
                :collections    => {
                  :User   => users,
                  :Ticket => tickets,
                }
              },
              :event      => [ 'loadCollection', 'ticket_overview_rebuild' ],
              :collection => 'ticket_overview_' + overview.meta[:url].to_s,
            })
          end
        }

        # recent viewed
        self.jobs_recent_viewed(
          user,
          client_id,
          state_client_ids[ client_id ],
          state_user_ids[ user.id ],
        )

        # activity stream
        self.jobs_activity_stream(
          user,
          client_id,
          state_client_ids[client_id],
          state_user_ids[ user.id ],
        )

        # ticket create
        self.jobs_create_attributes(
          user,
          client_id,
          state_client_ids[client_id],
          state_user_ids[ user.id ],
        )

        # system settings


        # rss view
        self.jobs_rss(
          user,
          client_id,
          state_client_ids[client_id],
          'http://www.heise.de/newsticker/heise-atom.xml'
        )
        sleep 1
      }
    end
  end

  def self.jobs_ticket(ticket_id, client_state, tickets, users)

    puts 'check :overview'

    if !client_state['tickets']
      client_state['tickets'] = {}
    end

    # add ticket if needed
    data = Ticket.full_data(ticket_id)
    if client_state['tickets'][ticket_id] != data
      client_state['tickets'][ticket_id] = data
      tickets.push data
    end

    # add users if needed
    self.jobs_user( data['owner_id'], client_state, users )
    self.jobs_user( data['customer_id'], client_state, users )
    self.jobs_user( data['created_by_id'], client_state, users )
  end

  def self.jobs_user(user_id, client_state, users)

    if !client_state['users']
      client_state['users'] = {}
    end

    # get user
    user = User.user_data_full( user_id )

    # user is already on client and not changed
    return if client_state['users'][ user_id ] == user

    puts 'push user ... ' + user['login']
    # user not on client or different
    users[ user_id ] = user
    client_state['users'][ user_id ] = user
  end

  # rss view
  def self.jobs_rss(user_id, client_id, client_state, url)

    # name space
    if !client_state[:rss_items]
      client_state[:rss_items] = {}
    end

    # only fetch every 5 minutes
    return if client_state[:rss_items][:last_run] && Time.new - client_state[:rss_items][:last_run] < 5.minutes

    # remember last run
    client_state[:rss_items][:last_run] = Time.new

    puts 'check :rss'
    # fetch rss
    rss_items = RSS.fetch( url, 8 )
    if client_state[:rss_items][:data] != rss_items
      client_state[:rss_items][:data] = rss_items

      # send update to browser  
      Session.transaction( client_id, {
        :event      => 'rss_rebuild',
        :collection => 'dashboard_rss',
        :data       => {
          head:  'Heise ATOM',
          items: rss_items,
        },
      })
    end
  end

  def self.jobs_recent_viewed(user, client_id, client_state, state_user )

    # name space
    if !client_state[:recent_viewed]
      client_state[:recent_viewed] = {}
    end

    # only fetch every x seconds
    return if client_state[:recent_viewed][:last_run] && Time.new - client_state[:recent_viewed][:last_run] < 4.seconds

    # remember last run
    client_state[:recent_viewed][:last_run] = Time.new

    puts 'check :recent_viewed'

    # fetch data
    if self.jobs_user_needed( state_user, :recent_viewed, 10.seconds )
      puts "fetch for user_id #{ user.id } :recent_viewed..."

      recent_viewed = History.recent_viewed(user)
      self.jobs_user_data_set( state_user, :recent_viewed, recent_viewed )
    else
      puts "use user_id #{ user.id } cache for :recent_viewed..."
      recent_viewed = self.jobs_user_data_get( state_user, :recent_viewed )
    end
    
    if client_state[:recent_viewed][:data] != recent_viewed
      client_state[:recent_viewed][:data] = recent_viewed

      # tickets and users 
      recent_viewed = History.recent_viewed_fulldata(user)

      # send update to browser  
      Session.transaction( client_id, {
        :data   => recent_viewed,
        :event  => 'update_recent_viewed',
      })
    end
  end

  def self.jobs_activity_stream(user, client_id, client_state, state_user)

    # name space
    if !client_state[:activity_stream]
      client_state[:activity_stream] = {}
    end

    # only fetch every x seconds
    return if client_state[:activity_stream][:last_run] && Time.new - client_state[:activity_stream][:last_run] < 8.seconds

    # remember last run
    client_state[:activity_stream][:last_run] = Time.new

    puts 'check :activity_stream'

    if self.jobs_user_needed( state_user, :activity_stream, 3.seconds )
      puts "fetch for user_id #{ user.id } :activity_stream..."

      activity_stream = History.activity_stream(user)
      self.jobs_user_data_set( state_user, :activity_stream, activity_stream )
    else
      puts "use user_id #{ user.id } cache for :activity_stream..."
      activity_stream = self.jobs_user_data_get( state_user, :activity_stream )
    end

    if client_state[:activity_stream][:data] != activity_stream
      client_state[:activity_stream][:data] = activity_stream

      activity_stream = History.activity_stream_fulldata(user)

      # send update to browser  
      Session.transaction( client_id, {
        :event      => 'activity_stream_rebuild',
        :collection => 'activity_stream', 
        :data       => activity_stream,
      })
    end
  end

  def self.jobs_create_attributes(user, client_id, client_state, state_user)

    # name space
    if !client_state[:create_attributes]
      client_state[:create_attributes] = {}
    end

    # only fetch every x seconds
    return if client_state[:create_attributes][:last_run] && Time.new - client_state[:create_attributes][:last_run] < 12.seconds

    # remember last run
    client_state[:create_attributes][:last_run] = Time.new

    puts 'check :create_attributes'
    if self.jobs_user_needed( state_user, :create_attributes, 26.seconds )
      puts "fetch for user_id #{ user.id } :create_attributes..."

      ticket_create_attributes = Ticket.create_attributes(
        :current_user_id => user.id,
      )
      self.jobs_user_data_set( state_user, :create_attributes, ticket_create_attributes )
    else
      puts "use user_id #{ user.id } cache for :create_attributes..."
      ticket_create_attributes = self.jobs_user_data_get( state_user, :create_attributes )
    end

    if client_state[:create_attributes][:data] != ticket_create_attributes
      client_state[:create_attributes][:data] = ticket_create_attributes

      # send update to browser  
      Session.transaction( client_id, {
        :data       => ticket_create_attributes,
        :collection => 'ticket_create_attributes',
      })
    end
  end

  def self.jobs_user_needed( item, key, ttl )

    if !item[key]
      item[key] = {}
    end

    # run needed on initial
    if !item[:last_run]

      # set new last run
      item[:last_run] = Time.new
      return true
    end

    # run needed if ttl is over
    if Time.new - item[:last_run] > ttl

      # set new last run
      item[:last_run] = Time.new
      return true
    end

    # no new run needed
    return false
  end

  def self.jobs_user_data_get( item, key )
    return item[key][:data]
  end

  def self.jobs_user_data_set( item, key, data )
    item[key][:data] = data
    return true
  end


  def self.sessions
    path = @path + '/'
    data = []
    Dir.foreach( path ) do |entry|
      if entry != '.' && entry != '..'
        data.push entry
      end
    end
    return data
  end
  
  def self.queue( client_id )
    path = @path + '/' + client_id.to_s + '/'
    data = []
    Dir.foreach( path ) do |entry|
      if /^transaction/.match( entry )
        data.push Session.queue_file( path + entry )
      end
    end
    return data
  end

  def self.queue_file( filename )
    data = nil
    File.open( filename, 'r' ) { |file|
      all = ''
      while line = file.gets  
        all = all + line  
      end
      data = JSON.parse( all )
    }
    File.delete( filename )
    return data
  end

  def self.destory( client_id )
    path = @path + '/' + client_id.to_s
    FileUtils.rm_rf path
  end

end
