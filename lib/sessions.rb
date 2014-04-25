require 'json'
require 'rss'
require 'session_helper'

module Sessions

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

  def self.spool_create( msg )
    path = @path + '/spool/'
    FileUtils.mkpath path
    file = Time.new.to_f.to_s + '-' + rand(99999).to_s
    File.open( path + '/' + file , 'wb' ) { |file|
      data = {
        :msg        => msg,
        :timestamp  => Time.now.to_i,
      }
#      puts 'CREATE' + Marshal.dump(data)
      file.write data.to_json
    }
  end

  def self.spool_list( timestamp, current_user_id )
    path = @path + '/spool/'
    FileUtils.mkpath path
    data = []
    to_delete = []
    files = []
    Dir.foreach( path ) {|entry|
      next if entry == '.' || entry == '..'
      files.push entry
    }
    files.sort.each {|entry|
      filename = path + '/' + entry
      next if !File::exists?( filename )
      File.open( filename, 'rb' ) { |file|
        all = file.read
        spool = JSON.parse( all )
        begin
          message_parsed = JSON.parse( spool['msg'] )
        rescue => e
          log 'error', "can't parse spool message: #{ message }, #{ e.inspect }"
          next
        end

        # ignore message older then 48h
        if spool['timestamp'] + (2 * 86400) < Time.now.to_i
          to_delete.push path + '/' + entry
          next
        end

        # add spool attribute to push spool info to clients
        message_parsed['spool'] = true

        # only send not already now messages
        if !timestamp || timestamp < spool['timestamp']

          # spool to recipient list
          if message_parsed['recipient'] && message_parsed['recipient']['user_id']
            message_parsed['recipient']['user_id'].each { |user_id|
              if current_user_id == user_id
                item = {
                  :type    => 'direct',
                  :message => message_parsed,
                }
                data.push item
              end
            }

          # spool to every client
          else
            item = {
              :type    => 'broadcast',
              :message => message_parsed,
            }
            data.push item
          end
        end
      }
    }
    to_delete.each {|file|
      File.delete(file)
    }
    return data
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
    return if !data
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
    filename = 'send-' + Time.new().to_f.to_s# + '-' + rand(99999999).to_s
    check = true
    count = 0
    while check
      if File::exists?( path + filename )
        count += 1
        filename = filename  + '-' + count
#        filename = filename  + '-' + rand(99999).to_s
#        filename = filename  + '-' + rand(99999).to_s
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
        session_data = Sessions.get( client_id )
        next if !session_data
        next if !session_data[:user]
        next if !session_data[:user][:id]
        user = User.find( session_data[:user][:id] )
        next if !user

        # start user thread
        start_user_thread = false
        if !@@user_threads[user.id]
          @@user_threads[user.id] = true
          @@user_threads[user.id] = Thread.new {
            thread_worker(user.id)
            @@user_threads[user.id] = nil
            puts "close user (#{user.id}) thread"
          }
          start_user_thread = true
        end

        # wait with client thread unil user thread has done some little work
        if start_user_thread
          sleep 0.5
        end

        # start client thread
        if !@@client_threads[client_id]
          @@client_threads[client_id] = true
          @@client_threads[client_id] = Thread.new {
            thread_client(client_id)
            @@client_threads[client_id] = nil
            puts "close client (#{client_id}) thread"
          }
        end
      }

      # system settings
      sleep 0.5
    end
  end

  def self.thread_worker(user_id, try_count = 0, try_run_time = Time.now)
      puts "LOOP WORKER #{user_id} - #{try_count}"
      begin
          Sessions::Worker.new(user_id)
      rescue => e
        puts "thread_worker exited with error #{ e.inspect }"
        sleep 10
        begin
          ActiveRecord::Base.connection.reconnect!
        rescue => e
          puts "Can't reconnect to database #{ e.inspect }"
        end

        try_run_max = 10
        try_count += 1

        # reset error counter if to old
        if try_run_time + ( 60 * 5 ) < Time.now
          try_count = 0
        end
        try_run_time = Time.now

        # restart worker again
        if try_run_max > try_count
          thread_worker(user_id, try_count, try_run_time)
        else
          raise "STOP thread_worker for user #{user_id} after #{try_run_max} tries"
        end
      end
      puts "/LOOP WORKER #{user_id} - #{try_count}"
  end

  def self.thread_client(client_id, try_count = 0, try_run_time = Time.now)
      puts "LOOP #{client_id} - #{try_count}"
      begin
        Sessions::Client.new(client_id)
      rescue => e
        puts "thread_client exited with error #{ e.inspect }"
        sleep 10
        begin
          ActiveRecord::Base.connection.reconnect!
        rescue => e
          puts "Can't reconnect to database #{ e.inspect }"
        end

        try_run_max = 10
        try_count += 1

        # reset error counter if to old
        if try_run_time + ( 60 * 5 ) < Time.now
          try_count = 0
        end
        try_run_time = Time.now

        # restart job again
        if try_run_max > try_count
          thread_client(client_id, try_count, try_run_time)
        else
          raise "STOP thread_client for client #{client_id} after #{try_run_max} tries"
        end
      end
      puts "/LOOP #{client_id} - #{try_count}"
  end

  def self.sessions
    path = @path + '/'

    # just make sure that spool path exists
    if !File::exists?( path )
      FileUtils.mkpath path
    end

    data = []
    Dir.foreach( path ) do |entry|
      next if entry == '.' || entry == '..' || entry == 'spool'
      data.push entry.to_s
    end
    return data
  end

  def self.queue( client_id )
    path = @path + '/' + client_id.to_s + '/'
    data = []
    files = []
    Dir.foreach( path ) {|entry|
      next if entry == '.' || entry == '..'
      files.push entry
    }
    files.sort.each {|entry|
      filename = path + '/' + entry
      if /^send/.match( entry )
        data.push Sessions.queue_file( path, entry )
      end
    }
    return data
  end

  def self.queue_file( path, filename )
    file_old = path + filename
    file_new = path + 'a-' + filename
    FileUtils.mv( file_old, file_new )
    data = nil
    all = ''
    File.open( file_new, 'rb' ) { |file|
      all = file.read
    }
    File.delete( file_new )
    data = JSON.parse( all )
    return data
  end

  def self.broadcast( data )

    # list all current clients
    client_list = self.list
    client_list.each {|local_client_id, local_client|
      Sessions.send( local_client_id, data )
    }
    return true
  end

  def self.destory( client_id )
    path = @path + '/' + client_id.to_s
    FileUtils.rm_rf path
  end

end