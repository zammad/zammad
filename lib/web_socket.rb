require 'json'

module Session
  @path = '/tmp/websocket'
  @@user_threads = {}
  @@client_threads = {}

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
    path = @path + '/' + client_id.to_s + '/'
    filename = 'transaction-' + Time.new().to_i.to_s + '-' + rand(999999).to_s
    if File::exists?( path + filename )
      filename = filename + '-1'
      if File::exists?( path + filename )
        filename = filename + '-1'
        if File::exists?( path + filename )
          filename = filename + '-1'
          if File::exists?( path + filename )
            filename = filename  + '-' + rand(999999).to_s
          end
        end
      end
    end
    return false if !File.directory? path
    File.open( path + 'a-' + filename, 'w' ) { |file|
      file.puts data.to_json
    }
    FileUtils.mv( path + 'a-' + filename, path + filename)
    return true
  end

  def self.jobs
    Thread.abort_on_exception = true
    while true
      client_ids = self.sessions
      client_ids.each { |client_id|

        # get current user  
        user_session = Session.get( client_id )
        next if !user_session
        next if !user_session[:id]
        user = User.find( user_session[:id] )
        next if !user

        # start user thread
        start_user_thread = false
        if !@@user_threads[user.id]
          start_user_thread = true
          @@user_threads[user.id] = Thread.new {
            UserState.new(user.id)
            @@user_threads[user.id] = nil
#            raise "Exception from thread"
          }
        end

        # wait with client thread unil user thread has done some little work
        if start_user_thread
          sleep 0.4
        end

        # start client thread
        if !@@client_threads[client_id]
          @@client_threads[client_id] = Thread.new {
            ClientState.new(client_id)
            @@client_threads[client_id] = nil
#            raise "Exception from thread"
          }
        end

        # system settings
        sleep 0.3
      }
    end
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
        data.push Session.queue_file( path, entry )
      end
    end
    return data
  end

  def self.queue_file( path, filename )
    file_old = path + filename
    file_new = path + 'a-' + filename
    FileUtils.mv( file_old, file_new )
    data = nil
    all = ''
    File.open( file_new, 'r' ) { |file|
      while line = file.gets  
        all = all + line  
      end
    }
    File.delete( file_new )
    data = JSON.parse( all )
    return data
  end

  def self.destory( client_id )
    path = @path + '/' + client_id.to_s
    FileUtils.rm_rf path
  end

end

module CacheIn
  @@data = {}
  @@expires_in = {}
  @@expires_in_ttl = {}
  def self.set( key, value, params = {} )
#    puts 'CacheIn.set:' + key + '-' + value.inspect
    if params[:expires_in]
      @@expires_in[key] = Time.now + params[:expires_in]
      @@expires_in_ttl[key] = params[:expires_in]
    end
    @@data[ key ] = value
  end
  def self.expired( key )
    if @@expires_in[key]
      return true if @@expires_in[key] < Time.now
      return false
    end
    return true
  end
  def self.get( key, params = {} )
#    puts 'CacheIn.get:' + key + '-' + @@data[ key ].inspect
    if !params[:re_expire]
      if @@expires_in[key]
        return if self.expired(key)
      end
    else
      if @@expires_in[key]
        @@expires_in[key] = Time.now + @@expires_in_ttl[key]
      end
    end
    @@data[ key ]
  end
end


class UserState
  def initialize( user_id )
    @user_id = user_id
    @data = {}
    @cache_key = 'user_' + user_id.to_s
    self.log "---user started user state"

    CacheIn.set( 'last_run_' + user_id.to_s , true, { :expires_in => 20.seconds } )

    self.fetch
  end
  
  def fetch
    user = User.find( @user_id )
    return if !user

    while true

      # check if user is still with min one open connection
      if !CacheIn.get( 'last_run_' + user.id.to_s )
        self.log "---user - closeing thread - no open user connection"
        return
      end

      self.log "---user - fetch user data"
      # overview
      cache_key = @cache_key + '_overview'
      if CacheIn.expired(cache_key)
        overview = Ticket.overview(
          :current_user_id => user.id,
        )
        overview_cache = CacheIn.get( cache_key, { :re_expire => true } )
        self.log 'fetch overview - ' + cache_key
        if overview != overview_cache
          self.log 'fetch overview changed - ' + cache_key
#          puts overview.inspect
#          puts '------'
#          puts overview_cache.inspect
          CacheIn.set( cache_key, overview, { :expires_in => 3.seconds } )
        end
      end

      # overview lists
      overviews = Ticket.overview_list(
        :current_user_id => user.id,
      )
      overviews.each { |overview|
        cache_key = @cache_key + '_overview_data_' + overview.meta[:url]
        if CacheIn.expired(cache_key)
          overview_data = Ticket.overview(
            :view            => overview.meta[:url],
#            :view_mode       => params[:view_mode],
            :current_user_id => user.id,
            :array           => true,
          )
          overview_data_cache = CacheIn.get( cache_key, { :re_expire => true } )
          self.log 'fetch overview_data - ' + cache_key
          if overview_data != overview_data_cache
            self.log 'fetch overview_data changed - ' + cache_key
            CacheIn.set( cache_key, overview_data, { :expires_in => 5.seconds } )
          end
        end
      }

      # create_attributes
      cache_key = @cache_key + '_ticket_create_attributes'
      if CacheIn.expired(cache_key)
        ticket_create_attributes = Ticket.create_attributes(
          :current_user_id => user.id,
        )
        ticket_create_attributes_cache = CacheIn.get( cache_key, { :re_expire => true } )
        self.log 'fetch ticket_create_attributes - ' + cache_key
        if ticket_create_attributes != ticket_create_attributes_cache
          self.log 'fetch ticket_create_attributes changed - ' + cache_key
          CacheIn.set( cache_key, ticket_create_attributes, { :expires_in => 2.minutes } )
        end
      end

      # recent viewed
      cache_key = @cache_key + '_recent_viewed'
      if CacheIn.expired(cache_key)
        recent_viewed = History.recent_viewed(user)
        recent_viewed_cache = CacheIn.get( cache_key, { :re_expire => true } )
        self.log 'fetch recent_viewed - ' + cache_key
        if recent_viewed != recent_viewed_cache
          self.log 'fetch recent_viewed changed - ' + cache_key

          recent_viewed_full = History.recent_viewed_fulldata(user)
          CacheIn.set( cache_key, recent_viewed, { :expires_in => 5.seconds } )
          CacheIn.set( cache_key + '_push', recent_viewed_full )
        end
      end

      # activity steam
      cache_key = @cache_key + '_activity_stream'
      if CacheIn.expired(cache_key)
        activity_stream = History.activity_stream( user )
        activity_stream_cache = CacheIn.get( cache_key, { :re_expire => true } )
        self.log 'fetch activity_stream - ' + cache_key
        if activity_stream != activity_stream_cache
          self.log 'fetch activity_stream changed - ' + cache_key

          activity_stream_full = History.activity_stream_fulldata( user )
          CacheIn.set( cache_key, activity_stream, { :expires_in => 0.75.minutes } )
          CacheIn.set( cache_key + '_push', activity_stream_full )
        end
      end

      # rss
      cache_key = @cache_key + '_rss'
      if CacheIn.expired(cache_key)
        url = 'http://www.heise.de/newsticker/heise-atom.xml'
        rss_items = RSS.fetch( url, 8 )
        rss_items_cache = CacheIn.get( cache_key, { :re_expire => true } )
        self.log 'fetch rss - ' + cache_key
        if rss_items != rss_items_cache
          self.log 'fetch rss changed - ' + cache_key
          CacheIn.set( cache_key, rss_items, { :expires_in => 2.minutes } )
          CacheIn.set( cache_key + '_push', {
            head:  'Heise ATOM',
            items: rss_items,
          })
        end
      end
      self.log "---/user-"
      sleep 1
    end
  end

  def log( data )
    puts "#{Time.now}:user_id(#{ @user_id }) #{ data }"
  end
end


class ClientState
  def initialize( client_id )
    @client_id = client_id
    @data = {}
    @pushed = {}
    self.log "---client start ws connection---"
    self.fetch
    self.log "---client exiting ws connection---"
  end
  
  def fetch
    while true

      # get connection user
      user_session = Session.get( @client_id )
      return if !user_session
      return if !user_session[:id]
      user = User.find( user_session[:id] )
      return if !user

      self.log "---client - looking for data of user #{user.id}"

      # remember last run
      CacheIn.set( 'last_run_' + user.id.to_s , true, { :expires_in => 20.seconds } )

      # overview
      cache_key = 'user_' + user.id.to_s + '_overview'
      overview = CacheIn.get( cache_key )
      if overview && @data[:overview] != overview
        @data[:overview] = overview
        self.log "push overview for user #{user.id}"

        # send update to browser
        self.transaction({
          :event  => 'navupdate_ticket_overview',
          :data   => overview,
        })
      end

      # overview_data
      overviews = Ticket.overview_list(
        :current_user_id => user.id,
      )
      overviews.each { |overview|
        cache_key = 'user_' + user.id.to_s + '_overview_data_' + overview.meta[:url]

        overview_data = CacheIn.get( cache_key )
        if overview_data && @data[cache_key] != overview_data
          @data[cache_key] = overview_data
          self.log "push overview_data for user #{user.id}"

          users = {}
          tickets = []
          overview_data[:tickets].each {|ticket_id|
            self.ticket( ticket_id, tickets, users )
          }
          # send update to browser
          self.transaction({
            :data   => {
              :overview      => overview_data[:overview],
              :ticket_list   => overview_data[:tickets],
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

      # ticket_create_attributes
      cache_key = 'user_' + user.id.to_s + '_ticket_create_attributes'
      ticket_create_attributes = CacheIn.get( cache_key )
      if ticket_create_attributes && @data[:ticket_create_attributes] != ticket_create_attributes
        @data[:ticket_create_attributes] = ticket_create_attributes
        self.log "push ticket_create_attributes for user #{user.id}"

        # send update to browser
        self.transaction({
          :collection => 'ticket_create_attributes',
          :data       => ticket_create_attributes,
        })
      end

      # recent viewed
      cache_key = 'user_' + user.id.to_s + '_recent_viewed'
      recent_viewed = CacheIn.get( cache_key )
      if recent_viewed && @data[:recent_viewed] != recent_viewed
        @data[:recent_viewed] = recent_viewed
        self.log "push recent_viewed for user #{user.id}"

        # send update to browser
        r = CacheIn.get( cache_key + '_push' )
        self.transaction({
          :event      => 'update_recent_viewed',
          :data       => r,
        })
      end

      # activity stream
      cache_key = 'user_' + user.id.to_s + '_activity_stream'
      activity_stream = CacheIn.get( cache_key )
      if activity_stream && @data[:activity_stream] != activity_stream
        @data[:activity_stream] = activity_stream
        self.log "push activity_stream for user #{user.id}"

        # send update to browser
        r = CacheIn.get( cache_key + '_push' )
        self.transaction({
          :event      => 'activity_stream_rebuild',
          :collection => 'activity_stream', 
          :data       => r,
        })
      end

      # rss
      cache_key = 'user_' + user.id.to_s + '_rss'
      rss_items = CacheIn.get( cache_key )
      if rss_items && @data[:rss] != rss_items
        @data[:rss] = rss_items
        self.log "push rss for user #{user.id}"

        # send update to browser
        r = CacheIn.get( cache_key + '_push' )
        self.transaction({
          :event      => 'rss_rebuild',
          :collection => 'dashboard_rss',
          :data       => r,
        })
      end
      self.log "---/client-"
#      sleep 1
      sleep 1
    end
  end

  # add ticket if needed
  def ticket( ticket_id, tickets, users )
    if !@pushed[:tickets]
      @pushed[:tickets] = {}
    end
    ticket = Ticket.full_data(ticket_id)
    if @pushed[:tickets][ticket_id] != ticket
      @pushed[:tickets][ticket_id] = ticket
      tickets.push ticket
    end

    # add users if needed
    self.user( ticket['owner_id'], users )
    self.user( ticket['customer_id'], users )
    self.user( ticket['created_by_id'], users )
  end

  # add user if needed
  def user( user_id, users )
    if !@pushed[:users]
      @pushed[:users] = {}
    end

    # get user
    user = User.user_data_full( user_id )

    # user is already on client and not changed
    return if @pushed[:users][ user_id ] == user
    @pushed[:users][user_id] = user

    # user not on client or different
    self.log 'push user ... ' + user['login']
    users[ user_id ] = user
  end

  # send update to browser
  def transaction( data )
    Session.transaction( @client_id, data )
  end

  def log( data )
    puts "#{Time.now}:client(#{ @client_id }) #{ data }"
  end
end