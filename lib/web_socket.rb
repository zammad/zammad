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

        # overviews
        result = Ticket.overview(
          :current_user_id => user.id,
        )
        if state_client_ids[client_id][:overview] != result
          state_client_ids[client_id][:overview] = result

          # send update to browser  
          Session.transaction( client_id, {
            :action => 'load',
            :data   => result,
            :event  => 'navupdate_ticket_overview',
          })
        end

        # recent viewed
        recent_viewed = History.recent_viewed(user)
        if state_client_ids[client_id][:recent_viewed] != recent_viewed
          state_client_ids[client_id][:recent_viewed] = recent_viewed

          # tickets and users 
          recent_viewed = History.recent_viewed_fulldata(user)

          # send update to browser  
          Session.transaction( client_id, {
            :action => 'load',
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
