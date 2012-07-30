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

        # overview meta data
        overview = Ticket.overview(
          :current_user_id => user.id,
        )
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
          overview_data = Ticket.overview(
            :view            => overview.meta[:url],
#            :view_mode       => params[:view_mode],
            :current_user_id => user.id,
            :array           => true,
          )
          
          if state_client_ids[client_id][:overview_data][ overview.meta[:url] ] != overview_data
            state_client_ids[client_id][:overview_data][ overview.meta[:url] ] = overview_data
puts 'push overview ' + overview.meta[:url].to_s
            users = {}
            tickets = []
            overview_data[:tickets].each {|ticket|
              data = Ticket.full_data(ticket.id)
              tickets.push data
              if !users[ data['owner_id'] ]
                users[ data['owner_id'] ] = User.user_data_full( data['owner_id'] )
              end
              if !users[ data['customer_id'] ]
                users[ data['customer_id'] ] = User.user_data_full( data['customer_id'] )
              end
              if !users[ data['created_by_id'] ]
                users[ data['created_by_id'] ] = User.user_data_full( data['created_by_id'] )
              end
            }

            # send update to browser  
            Session.transaction( client_id, {
              :data   => {
                :overview      => overview_data[:overview],
                :tickets       => tickets,
                :tickets_count => overview_data[:tickets_count],
                :users         => users,
              },
              :event      => 'ticket_overview_rebuild',
              :collection => 'ticket_overview_' + overview.meta[:url].to_s,
            })
          end
        }

        # recent viewed
        recent_viewed = History.recent_viewed(user)
        if state_client_ids[client_id][:recent_viewed] != recent_viewed
          state_client_ids[client_id][:recent_viewed] = recent_viewed

          # tickets and users 
          recent_viewed = History.recent_viewed_fulldata(user)

          # send update to browser  
          Session.transaction( client_id, {
            :data   => recent_viewed,
            :event  => 'update_recent_viewed',
          })
        end

        # activity stream
        activity_stream = History.activity_stream(user)
        if state_client_ids[client_id][:activity_stream] != activity_stream
          state_client_ids[client_id][:activity_stream] = activity_stream

          activity_stream = History.activity_stream_fulldata(user)

          # send update to browser  
          Session.transaction( client_id, {
            :event      => 'activity_stream_rebuild',
            :collection => 'activity_stream', 
            :data       => activity_stream,
          })
        end

        # ticket create
        ticket_create_attributes = Ticket.create_attributes(
          :current_user_id => user.id,
        )
        if state_client_ids[client_id][:ticket_create_attributes] != ticket_create_attributes
          state_client_ids[client_id][:ticket_create_attributes] = ticket_create_attributes

          # send update to browser  
          Session.transaction( client_id, {
            :data       => ticket_create_attributes,
            :collection => 'ticket_create_attributes',
          })
        end

        # system settings



        # rss view
        rss_items = RSS.fetch( 'http://www.heise.de/newsticker/heise-atom.xml', 8 )
        if state_client_ids[client_id][:rss_items] != rss_items
          state_client_ids[client_id][:rss_items] = rss_items

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
        sleep 1
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
