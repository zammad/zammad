require 'json'
require 'rss'

module Session

  # get application root directory
  @root = Dir.pwd.to_s
  if !@root || @root.empty? || @root == '/'
    @root = Rails.root
  end

  # get working directories
  @path = @root + '/tmp/websocket'
  @pid  = @root + '/tmp/pids/sessionworker.pid'

  # create global vars for threads
  @@user_threads = {}
  @@client_threads = {}

  def self.create( client_id, session, meta )
    path = @path + '/' + client_id.to_s
    FileUtils.mkpath path
    meta[:last_ping] = Time.new.to_i.to_s
    File.open( path + '/session', 'wb' ) { |file|
      data = {
        :user => {
          :id => session['id'],
        },
        :meta => meta,
      }
#      puts 'CREATE' + Marshal.dump(data)
      file.write Marshal.dump(data)
    }

    # send update to browser
    if session['id']
      self.send( client_id, {
        :event  => 'ws:login',
        :data   => { :success => true },
      })
    end
  end

  def self.list
    client_ids = self.sessions
    session_list = {}
    client_ids.each { |client_id|
      data = self.get(client_id)
      next if !data
      session_list[client_id] = data
    }
    return session_list
  end

  def self.touch( client_id )
    data = self.get(client_id)
    path = @path + '/' + client_id.to_s
    data[:meta][:last_ping] = Time.new.to_i.to_s
    File.open( path + '/session', 'wb' ) { |file|
      file.write Marshal.dump(data)
    }
    return true
  end

  def self.get( client_id )
    session_file = @path + '/' + client_id.to_s + '/session'
    data = nil
    return if !File.exist? session_file
    begin
      File.open( session_file, 'rb' ) { |file|
        file.flock( File::LOCK_EX )
        all = file.read
        file.flock( File::LOCK_UN )
        data = Marshal.load( all )
      }
    rescue Exception => e
      File.delete(session_file)
      puts "Error reading '#{session_file}':"
      puts e.inspect
      return
    end
    return data
  end

  def self.send( client_id, data )
    path = @path + '/' + client_id.to_s + '/'
    filename = 'send-' + Time.new().to_i.to_s + '-' + rand(99999999).to_s
    check = true
    while check
      if File::exists?( path + filename )
        filename = filename  + '-' + rand(99999).to_s
      else
        check = false
      end    
    end
    return false if !File.directory? path
    File.open( path + 'a-' + filename, 'wb' ) { |file|
      file.flock( File::LOCK_EX )
      file.write data.to_json
      file.flock( File::LOCK_UN )
      file.close
    }
    return false if !File.exists?( path + 'a-' + filename )
    FileUtils.mv( path + 'a-' + filename, path + filename )
    return true
  end

  def self.jobs

    # just make sure that spool path exists
    if !File::exists?( @path )
      FileUtils.mkpath @path
    end

    Thread.abort_on_exception = true
    while true
      client_ids = self.sessions
      client_ids.each { |client_id|

        # connection already open
        next if @@client_threads[client_id]

        # get current user  
        session_data = Session.get( client_id )
        next if !session_data
        next if !session_data[:user]
        next if !session_data[:user][:id]
        user = User.find( session_data[:user][:id] )
        next if !user

        # start user thread
        start_user_thread = false
        if !@@user_threads[user.id]
          start_user_thread = true
          @@user_threads[user.id] = Thread.new {
            UserState.new(user.id)
            @@user_threads[user.id] = nil
            puts "close user(#{user.id}) thread"
#            raise "Exception from thread"
          }
        end

        # wait with client thread unil user thread has done some little work
        if start_user_thread
          sleep 0.5
        end

        # start client thread
        if !@@client_threads[client_id]
          @@client_threads[client_id] = Thread.new {
            ClientState.new(client_id)
            @@client_threads[client_id] = nil
            puts "close client(#{client_id}) thread"
#            raise "Exception from thread"
          }
        end
      }

      # system settings
      sleep 0.5
    end
  end

  def self.sessions
    path = @path + '/'

    # just make sure that spool path exists
    if !File::exists?( path )
      FileUtils.mkpath path
    end

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
      if /^send/.match( entry )
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
    File.open( file_new, 'rb' ) { |file|
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
  @@data_time = {}
  @@expires_in = {}
  @@expires_in_ttl = {}

  def self.set( key, value, params = {} )
#    puts 'CacheIn.set:' + key + '-' + value.inspect
    if params[:expires_in]
      @@expires_in[key] = Time.now + params[:expires_in]
      @@expires_in_ttl[key] = params[:expires_in]
    end
    @@data[ key ] = value
    @@data_time[ key ] = Time.now
  end

  def self.expired( key, params = {} )

    # expire if value never was set
    return true if !@@data.include? key

    # ignore_expire
    return false if params[:ignore_expire]

    # set re_expire
    if params[:re_expire]
      if @@expires_in[key]
        @@expires_in[key] = Time.now + @@expires_in_ttl[key]
      end
      return false
    end

    # check if expired
    if @@expires_in[key]
      return true if @@expires_in[key] < Time.now
      return false
    end

    # return false if key was set without expires_in
    return false
  end

  def self.get_time( key, params = {} )
    data = self.get( key, params )
    if data
      return @@data_time[key]
    end
    return nil
  end

  def self.get( key, params = {} )
#    puts 'CacheIn.get:' + key + '-' + @@data[ key ].inspect
    return if self.expired( key, params )
    @@data[ key ]
  end
end


class UserState
  def initialize( user_id )
    @user_id = user_id
    @data = {}
    @cache_key = 'user_' + user_id.to_s
    self.log 'notify', "---user started user state"

    CacheIn.set( 'last_run_' + user_id.to_s , true, { :expires_in => 20.seconds } )

    self.fetch
  end

  def fetch
    user = User.find( @user_id )
    return if !user

    while true

      # check if user is still with min one open connection
      if !CacheIn.get( 'last_run_' + user.id.to_s )
        self.log 'notify', "---user - closeing thread - no open user connection"
        return
      end

      self.log 'notice', "---user - fetch user data"
      # overview
      cache_key = @cache_key + '_overview'
      if CacheIn.expired(cache_key)
        overview = Ticket.overview(
          :current_user => user,
        )
        overview_cache = CacheIn.get( cache_key, { :re_expire => true } )
        self.log 'notice', 'fetch overview - ' + cache_key
        if overview != overview_cache
          self.log 'notify', 'fetch overview changed - ' + cache_key
#          puts overview.inspect
#          puts '------'
#          puts overview_cache.inspect
          CacheIn.set( cache_key, overview, { :expires_in => 3.seconds } )
        end
      end

      # overview lists
      overviews = Ticket.overview_list(
        :current_user => user,
      )
      overviews.each { |overview|
        cache_key = @cache_key + '_overview_data_' + overview.link
        if CacheIn.expired(cache_key)
          overview_data = Ticket.overview(
            :view         => overview.link,
#            :view_mode    => params[:view_mode],
            :current_user => user,
            :array        => true,
          )
          overview_data_cache = CacheIn.get( cache_key, { :re_expire => true } )
          self.log 'notice', 'fetch overview_data - ' + cache_key
          if overview_data != overview_data_cache
            self.log 'notify', 'fetch overview_data changed - ' + cache_key
            CacheIn.set( cache_key, overview_data, { :expires_in => 5.seconds } )
          end
        end
      }

      # create_attributes
      cache_key = @cache_key + '_ticket_create_attributes'
      if CacheIn.expired(cache_key)
        ticket_create_attributes = Ticket.attributes_to_change(
          :current_user_id => user.id,
        )
        ticket_create_attributes_cache = CacheIn.get( cache_key, { :re_expire => true } )
        self.log 'notice', 'fetch ticket_create_attributes - ' + cache_key
        if ticket_create_attributes != ticket_create_attributes_cache
          self.log 'notify', 'fetch ticket_create_attributes changed - ' + cache_key
          CacheIn.set( cache_key, ticket_create_attributes, { :expires_in => 2.minutes } )
        end
      end

      # recent viewed
      cache_key = @cache_key + '_recent_viewed'
      if CacheIn.expired(cache_key)
        recent_viewed = History.recent_viewed( user )
        recent_viewed_cache = CacheIn.get( cache_key, { :re_expire => true } )
        self.log 'notice', 'fetch recent_viewed - ' + cache_key
        if recent_viewed != recent_viewed_cache
          self.log 'notify', 'fetch recent_viewed changed - ' + cache_key

          recent_viewed_full = History.recent_viewed_fulldata( user )
          CacheIn.set( cache_key, recent_viewed, { :expires_in => 5.seconds } )
          CacheIn.set( cache_key + '_push', recent_viewed_full )
        end
      end

      # activity steam
      cache_key = @cache_key + '_activity_stream'
      if CacheIn.expired(cache_key)
        activity_stream = History.activity_stream( user )
        activity_stream_cache = CacheIn.get( cache_key, { :re_expire => true } )
        self.log 'notice', 'fetch activity_stream - ' + cache_key
        if activity_stream != activity_stream_cache
          self.log 'notify', 'fetch activity_stream changed - ' + cache_key

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
        self.log 'notice', 'fetch rss - ' + cache_key
        if rss_items != rss_items_cache
          self.log 'notify', 'fetch rss changed - ' + cache_key
          CacheIn.set( cache_key, rss_items, { :expires_in => 2.minutes } )
          CacheIn.set( cache_key + '_push', {
            head:  'Heise ATOM',
            items: rss_items,
          })
        end
      end

      # auto population of default collections
      self.log 'notice', "---user - fetch push_collection data"

      # get available collections
      cache_key = @cache_key + '_push_collections'
      collections = CacheIn.get( cache_key )
      if !collections
        collections = {}
        push_collection = SessionHelper::push_collections(user)
        push_collection.each { | key, value |
          collections[ key ] = true
        }
        CacheIn.set( cache_key, collections, { :expires_in => 2.minutes } )
      end

      # check all collections to push
      push_collection = {}
      collections.each { | key, v |
        cache_key = @cache_key + '_push_collections_' + key
        if CacheIn.expired(cache_key)
          if push_collection.empty?
            push_collection = SessionHelper::push_collections(user)
          end
          push_collection_cache = CacheIn.get( cache_key, { :re_expire => true } )
          self.log 'notice', "---user - fetch push_collection data " + cache_key
          if !push_collection[key] || !push_collection_cache || push_collection[key] != push_collection_cache || !push_collection[ key ].zip( push_collection_cache ).all? { |x, y| x.attributes == y.attributes }
            self.log 'notify', 'fetch push_collection changed - ' + cache_key
            CacheIn.set( cache_key, push_collection[key], { :expires_in => 1.minutes } )
          end
        end
      }

      self.log 'notice', "---/user-"
      sleep 1
    end
  end

  def log( level, data )
    return if level == 'notice'
    puts "#{Time.now}:user_id(#{ @user_id }) #{ data }"
  end
end


class ClientState
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
      session_data = Session.get( @client_id )
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
      CacheIn.set( 'last_run_' + user.id.to_s , true, { :expires_in => 20.seconds } )

      # verify already pushed data
      if !CacheIn.get( 'pushed_users' + @client_id.to_s )
        CacheIn.set( 'pushed_users' + @client_id.to_s , true, { :expires_in => 20.seconds } )
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
                :collections => {
                  :User   => users,
                },
              },
              :event => [ 'loadCollection', 'ticket_overview_rebuild' ],
            });
          end
        end
      end

      # verify already pushed data
      if !CacheIn.get( 'pushed_tickets' + @client_id.to_s )
        CacheIn.set( 'pushed_tickets' + @client_id.to_s , true, { :expires_in => 20.seconds } )
        if @pushed[:tickets]
          tickets = []
          users = {}
          @pushed[:tickets].each {|ticket_id, ticket_data|
            self.ticket( ticket_id, tickets, users )
          }
          if !tickets.empty?
            tickets.each {|ticket|
              self.log 'notify', "push update of already pushed ticket id #{ticket['id']}"
            }
            # send update to browser
            self.send({
              :data   => {
                :collections => {
                  :Ticket => tickets,
                  :User   => users,
                },
              },
              :event => [ 'loadCollection', 'ticket_overview_rebuild' ],
            });
          end
        end
      end

      # overview
      cache_key = @cache_key + '_overview'
      overview_time = CacheIn.get_time( cache_key, { :ignore_expire => true } )
      if overview_time && @data[:overview_time] != overview_time
        @data[:overview_time] = overview_time
        overview = CacheIn.get( cache_key, { :ignore_expire => true } )

        self.log 'notify', "push overview for user #{user.id}"

        # send update to browser
        self.send({
          :event  => 'navupdate_ticket_overview',
          :data   => overview,
        })
      end

      # overview_data
      overviews = Ticket.overview_list(
        :current_user => user,
      )
      overviews.each { |overview|
        cache_key = @cache_key + '_overview_data_' + overview.link

        overview_data_time = CacheIn.get_time( cache_key, { :ignore_expire => true } )
        if overview_data_time && @data[cache_key] != overview_data_time
          @data[cache_key] = overview_data_time
          overview_data = CacheIn.get( cache_key, { :ignore_expire => true } )
          self.log 'notify', "push overview_data #{overview.link} for user #{user.id}"
          users = {}
          tickets = []
          overview_data[:ticket_list].each {|ticket_id|
            self.ticket( ticket_id, tickets, users )
          }

          # get groups
          group_ids = []
          Group.where( :active => true ).each { |group|
            group_ids.push group.id
          }
          agents = {}
          Ticket.agents.each { |user|
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
          self.send({
            :data   => {
              :overview      => overview_data[:overview],
              :ticket_list   => overview_data[:ticket_list],
              :tickets_count => overview_data[:tickets_count],
              :collections    => {
                :User   => users,
                :Ticket => tickets,
              },
              :bulk => {
                :group_id__owner_id => groups_users,
                :owner_id           => [],
              },
            },
            :event      => [ 'loadCollection', 'ticket_overview_rebuild' ],
            :collection => 'ticket_overview_' + overview.link.to_s,
          })
        end
      }

      # ticket_create_attributes
      cache_key = @cache_key + '_ticket_create_attributes'
      ticket_create_attributes_time = CacheIn.get_time( cache_key, { :ignore_expire => true } )
      if ticket_create_attributes_time && @data[:ticket_create_attributes_time] != ticket_create_attributes_time
        @data[:ticket_create_attributes_time] = ticket_create_attributes_time
        create_attributes = CacheIn.get( cache_key, { :ignore_expire => true } )
        users = {}
        create_attributes[:owner_id].each {|user_id|
          if !users[user_id]
            users[user_id] = User.user_data_full(user_id)
          end
        }
        data = {
          :users     => users,
          :edit_form => create_attributes,
        }
        self.log 'notify', "push ticket_create_attributes for user #{user.id}"

        # send update to browser
        self.send({
          :collection => 'ticket_create_attributes',
          :data       => data,
        })
      end

      # recent viewed
      cache_key = @cache_key + '_recent_viewed'
      recent_viewed_time = CacheIn.get_time( cache_key, { :ignore_expire => true } )
      if recent_viewed_time && @data[:recent_viewed_time] != recent_viewed_time
        @data[:recent_viewed_time] = recent_viewed_time
        recent_viewed = CacheIn.get( cache_key, { :ignore_expire => true } )
        self.log 'notify', "push recent_viewed for user #{user.id}"

        # send update to browser
        r = CacheIn.get( cache_key + '_push', { :ignore_expire => true } )
        self.send({
          :event      => 'update_recent_viewed',
          :data       => r,
        })
      end

      # activity stream
      cache_key = @cache_key + '_activity_stream'
      activity_stream_time = CacheIn.get_time( cache_key, { :ignore_expire => true } )
      if activity_stream_time && @data[:activity_stream_time] != activity_stream_time
        @data[:activity_stream_time] = activity_stream_time
        activity_stream = CacheIn.get( cache_key, { :ignore_expire => true } )
        self.log 'notify', "push activity_stream for user #{user.id}"

        # send update to browser
        r = CacheIn.get( cache_key + '_push', { :ignore_expire => true } )
        self.send({
          :event      => 'activity_stream_rebuild',
          :collection => 'activity_stream', 
          :data       => r,
        })
      end

      # rss
      cache_key = @cache_key + '_rss'
      rss_items_time = CacheIn.get_time( cache_key, { :ignore_expire => true } )
      if rss_items_time && @data[:rss_time] != rss_items_time
        @data[:rss_time] = rss_items_time
        rss_items = CacheIn.get( cache_key, { :ignore_expire => true } )
        self.log 'notify', "push rss for user #{user.id}"

        # send update to browser
        r = CacheIn.get( cache_key + '_push', { :ignore_expire => true } )
        self.send({
          :event      => 'rss_rebuild',
          :collection => 'dashboard_rss',
          :data       => r,
        })
      end

      # push_collections
      cache_key = @cache_key + '_push_collections'
      collections = CacheIn.get( cache_key ) || {}
      collections.each { | key, v |
        collection_cache_key = @cache_key + '_push_collections_' + key
        collection_time = CacheIn.get_time( collection_cache_key, { :ignore_expire => true } )
        if collection_time && @data[ collection_cache_key + '_time' ] != collection_time

          @data[ collection_cache_key + '_time' ] = collection_time
          push_collections = CacheIn.get( collection_cache_key, { :ignore_expire => true } )

          self.log 'notify', "push push_collections #{key} for user #{user.id}"

          # send update to browser
          data = {}
          data['collections'] = {}
          data['collections'][key] = push_collections
          self.send({
            :event  => 'resetCollection',
            :data   => data,
          })

        end
      }

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
    return if @pushed[:users][ user_id ] == user['updated_at']
    @pushed[:users][user_id] = user['updated_at']

    # user not on client or different
    self.log 'notice', 'push user ... ' + user['login']
    users[ user_id ] = user
  end

  # send update to browser
  def send( data )
    Session.send( @client_id, data )
  end

  def log( level, data )
    return if level == 'notice'
    puts "#{Time.now}:client(#{ @client_id }) #{ data }"
  end
end