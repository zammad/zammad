# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Sessions

  # get application root directory
  @root = Dir.pwd.to_s
  if @root.blank? || @root == '/'
    @root = Rails.root
  end

  # get working directories
  @path = "#{@root}/tmp/websocket_#{Rails.env}"

  # create global vars for threads
  @@client_threads = {} # rubocop:disable Style/ClassVars

=begin

start new session

  Sessions.create(client_id, session_data, { type: 'websocket' })

returns

  true|false

=end

  def self.create(client_id, session, meta)
    path         = "#{@path}/#{client_id}"
    path_tmp     = "#{@path}/tmp/#{client_id}"
    session_file = "#{path_tmp}/session"

    # collect session data
    meta[:last_ping] = Time.now.utc.to_i
    data = {
      user: session,
      meta: meta,
    }
    content = data.to_json

    # store session data in session file
    FileUtils.mkpath path_tmp
    File.open(session_file, 'wb') do |file|
      file.write content
    end

    # destroy old session if needed
    if File.exist?(path)
      Sessions.destroy(client_id)
    end

    # move to destination directory
    FileUtils.mv(path_tmp, path)

    # send update to browser
    return if !session || session['id'].blank?

    send(
      client_id,
      {
        event: 'ws:login',
        data:  { success: true },
      }
    )
  end

=begin

list of all session

  client_ids = Sessions.sessions

returns

  ['4711', '4712']

=end

  def self.sessions
    path = "#{@path}/"

    # just make sure that spool path exists
    if !File.exist?(path)
      FileUtils.mkpath path
    end

    data = []
    Dir.foreach(path) do |entry|
      next if entry == '.'
      next if entry == '..'
      next if entry == 'tmp'
      next if entry == 'spool'

      data.push entry.to_s
    end
    data
  end

=begin

list of all session

  Sessions.session_exists?(client_id)

returns

  true|false

=end

  def self.session_exists?(client_id)
    session_dir = "#{@path}/#{client_id}"
    return false if !File.exist?(session_dir)

    session_file = "#{session_dir}/session"
    return false if !File.exist?(session_file)

    true
  end

=begin

list of all session with data

  client_ids_with_data = Sessions.list

returns

  {
    '4711' => {
      user: {
        'id' => 123,
      },
      meta: {
        type: 'websocket',
        last_ping: time_of_last_ping,
      }
    },
    '4712' => {
      user: {
        'id' => 124,
      },
      meta: {
        type: 'ajax',
        last_ping: time_of_last_ping,
      }
    },
  }

=end

  def self.list
    client_ids = sessions
    session_list = {}
    client_ids.each do |client_id|
      data = get(client_id)
      next if !data

      session_list[client_id] = data
    end
    session_list
  end

=begin

destroy session

  Sessions.destroy(client_id)

returns

  true|false

=end

  def self.destroy(client_id)
    path = "#{@path}/#{client_id}"
    FileUtils.rm_rf path
  end

=begin

destroy idle session

  list_of_client_ids = Sessions.destroy_idle_sessions

returns

  ['4711', '4712']

=end

  def self.destroy_idle_sessions(idle_time_in_sec = 240)
    list_of_closed_sessions = []
    clients                 = Sessions.list
    clients.each do |client_id, client|
      if !client[:meta] || !client[:meta][:last_ping] || ( client[:meta][:last_ping].to_i + idle_time_in_sec ) < Time.now.utc.to_i
        list_of_closed_sessions.push client_id
        Sessions.destroy(client_id)
      end
    end
    list_of_closed_sessions
  end

=begin

touch session

  Sessions.touch(client_id)

returns

  true|false

=end

  def self.touch(client_id)
    data = get(client_id)
    return false if !data

    path = "#{@path}/#{client_id}"
    data[:meta][:last_ping] = Time.now.utc.to_i
    File.open("#{path}/session", 'wb' ) do |file|
      file.flock(File::LOCK_EX)
      file.write data.to_json
      file.flock(File::LOCK_UN)
    end
    true
  end

=begin

get session data

  data = Sessions.get(client_id)

returns

  {
    user: {
      'id' => 123,
    },
    meta: {
      type: 'websocket',
      last_ping: time_of_last_ping,
    }
  }

=end

  def self.get(client_id)
    session_dir  = "#{@path}/#{client_id}"
    session_file = "#{session_dir}/session"
    data         = nil

    # if no session dir exists, session got destoried
    if !File.exist?(session_dir)
      destroy(client_id)
      log('debug', "missing session directory #{session_dir} for '#{client_id}', remove session.")
      return
    end

    # if only session file is missing, then it's an error behavior
    if !File.exist?(session_file)
      destroy(client_id)
      log('error', "missing session file for '#{client_id}', remove session.")
      return
    end
    begin
      File.open(session_file, 'rb') do |file|
        file.flock(File::LOCK_SH)
        all = file.read
        file.flock(File::LOCK_UN)
        data_json = JSON.parse(all)
        if data_json
          data        = symbolize_keys(data_json)
          data[:user] = data_json['user'] # for compat. reasons
        end
      end
    rescue => e
      log('error', e.inspect)
      destroy(client_id)
      log('error', "error in reading/parsing session file '#{session_file}', remove session.")
      return
    end
    data
  end

=begin

send message to client

  Sessions.send(client_id_of_recipient, data)

returns

  true|false

=end

  def self.send(client_id, data)
    path     = "#{@path}/#{client_id}/"
    filename = "send-#{Time.now.utc.to_f}"
    location = "#{path}#{filename}"
    check    = true
    count    = 0
    while check
      if File.exist?(location)
        count += 1
        location = "#{path}#{filename}-#{count}"
      else
        check = false
      end
    end
    return false if !File.directory? path

    begin
      File.open(location, 'wb') do |file|
        file.flock(File::LOCK_EX)
        file.write data.to_json
        file.flock(File::LOCK_UN)
        file.close
      end
    rescue => e
      log('error', e.inspect)
      log('error', "error in writing message file '#{location}'")
      return false
    end
    true
  end

=begin

send message to recipient client

  Sessions.send_to(user_id, data)

e. g.

  Sessions.send_to(user_id, {
    event: 'session:takeover',
    data: {
      taskbar_id: 12312
    },
  })

returns

  true|false

=end

  def self.send_to(user_id, data)

    # list all current clients
    client_list = sessions
    client_list.each do |client_id|
      session = Sessions.get(client_id)
      next if !session
      next if !session[:user]
      next if !session[:user]['id']
      next if session[:user]['id'].to_i != user_id.to_i

      Sessions.send(client_id, data)
    end
    true
  end

=begin

send message to all authenticated client

  Sessions.broadcast(data)

returns

  [array_with_client_ids_of_recipients]

broadcase also to not authenticated client

  Sessions.broadcast(data, 'public') # public|authenticated

broadcase also not to sender

  Sessions.broadcast(data, 'public', sender_user_id)

=end

  def self.broadcast(data, recipient = 'authenticated', sender_user_id = nil)

    # list all current clients
    recipients = []
    client_list = sessions
    client_list.each do |client_id|
      session = Sessions.get(client_id)
      next if !session

      if recipient != 'public'
        next if session[:user].blank?
        next if session[:user]['id'].blank?
      end

      next if sender_user_id && session[:user] && session[:user]['id'] && session[:user]['id'].to_i == sender_user_id.to_i

      Sessions.send(client_id, data)
      recipients.push client_id
    end
    recipients
  end

=begin

get messages for client

  messages = Sessions.queue(client_id_of_recipient)

returns

  [
    {
      key1 => 'some data of message 1',
      key2 => 'some data of message 1',
    },
    {
      key1 => 'some data of message 2',
      key2 => 'some data of message 2',
    },
  ]

=end

  def self.queue(client_id)
    path  = "#{@path}/#{client_id}/"
    data  = []
    files = []
    Dir.foreach(path) do |entry|
      next if entry == '.'
      next if entry == '..'

      files.push entry
    end
    files.sort.each do |entry|
      next if !entry.start_with?('send')

      message = Sessions.queue_file_read(path, entry)
      next if !message

      data.push message
    end
    data
  end

  def self.queue_file_read(path, filename)
    location = "#{path}#{filename}"
    message = ''
    File.open(location, 'rb') do |file|
      file.flock(File::LOCK_EX)
      message = file.read
      file.flock(File::LOCK_UN)
    end
    File.delete(location)
    return if message.blank?

    begin
      JSON.parse(message)
    rescue => e
      log('error', "can't parse queue message: #{message}, #{e.inspect}")
      nil
    end
  end

=begin

remove all session and spool messages

  Sessions.cleanup

=end

  def self.cleanup
    return true if !File.exist?(@path)

    FileUtils.rm_rf @path
    true
  end

=begin

create spool messages

  Sessions.spool_create(some: 'data')

=end

  def self.spool_create(data)
    msg = JSON.generate(data)
    path = "#{@path}/spool/"
    FileUtils.mkpath path
    data = {
      msg:       msg,
      timestamp: Time.now.utc.to_i,
    }
    file_path = "#{path}/#{Time.now.utc.to_f}-#{rand(99_999)}"
    File.open(file_path, 'wb') do |file|
      file.flock(File::LOCK_EX)
      file.write data.to_json
      file.flock(File::LOCK_UN)
    end
  end

=begin

get spool messages

  Sessions.spool_list(junger_then, for_user_id)

=end

  def self.spool_list(timestamp, current_user_id)
    path = "#{@path}/spool/"
    FileUtils.mkpath path

    data      = []
    to_delete = []
    files     = []
    Dir.foreach(path) do |entry|
      next if entry == '.'
      next if entry == '..'

      files.push entry
    end
    files.sort.each do |entry|
      filename = "#{path}/#{entry}"
      next if !File.exist?(filename)

      File.open(filename, 'rb') do |file|
        file.flock(File::LOCK_SH)
        message = file.read
        file.flock(File::LOCK_UN)
        message_parsed = {}
        begin
          spool = JSON.parse(message)
          message_parsed = JSON.parse(spool['msg'])
        rescue => e
          log('error', "can't parse spool message: #{message}, #{e.inspect}")
          to_delete.push "#{path}/#{entry}"
          next
        end

        # ignore message older then 48h
        if spool['timestamp'] + (2 * 86_400) < Time.now.utc.to_i
          to_delete.push "#{path}/#{entry}"
          next
        end

        # add spool attribute to push spool info to clients
        message_parsed['spool'] = true

        # only send not already older messages
        if !timestamp || timestamp < spool['timestamp']

          # spool to recipient list
          if message_parsed['recipient'] && message_parsed['recipient']['user_id']

            message_parsed['recipient']['user_id'].each do |user_id|

              next if current_user_id != user_id

              message = message_parsed
              if message_parsed['event'] == 'broadcast'
                message = message_parsed['data']
              end

              item = {
                type:    'direct',
                message: message,
              }
              data.push item
            end

          # spool to every client
          else
            message = message_parsed
            if message_parsed['event'] == 'broadcast'
              message = message_parsed['data']
            end
            item = {
              type:    'broadcast',
              message: message,
            }
            data.push item
          end
        end
      end
    end
    to_delete.each do |file|
      File.delete(file)
    end
    data
  end

=begin

delete spool messages

  Sessions.spool_delete

=end

  def self.spool_delete
    path = "#{@path}/spool/"
    FileUtils.rm_rf path
  end

  def self.jobs(node_id = nil)

    # just make sure that spool path exists
    if !File.exist?(@path)
      FileUtils.mkpath(@path)
    end

    # dispatch sessions
    if node_id.blank? && ENV['ZAMMAD_SESSION_JOBS_CONCURRENT'].to_i.positive?

      previous_nodes_sessions = Sessions::Node.stats
      if previous_nodes_sessions.present?
        log('info', "Cleaning up previous Sessions::Node sessions: #{previous_nodes_sessions}")
        Sessions::Node.cleanup
      end

      dispatcher_pid = Process.pid
      node_count     = ENV['ZAMMAD_SESSION_JOBS_CONCURRENT'].to_i
      node_pids      = []
      (1..node_count).each do |worker_node_id|
        node_pids << fork do
          title         = "Zammad Session Jobs Node ##{worker_node_id}: dispatch_pid:#{dispatcher_pid} -> worker_pid:#{Process.pid}"
          $PROGRAM_NAME = title

          log('info', "#{title} started.")

          ::Sessions.jobs(worker_node_id)
          sleep node_count
        rescue Interrupt
          nil
        end
      end

      Signal.trap 'SIGTERM' do

        node_pids.each do |node_pid|
          Process.kill 'TERM', node_pid
        end

        Process.waitall

        raise SignalException, 'SIGTERM'
      end

      # dispatch client_ids to nodes
      loop do

        # nodes
        nodes_stats = Sessions::Node.stats

        client_ids = sessions
        client_ids.each do |client_id|

          # ask nodes for nodes
          next if nodes_stats[client_id]

          # assign to node
          Sessions::Node.session_assigne(client_id)
          sleep 1
        end
        sleep 1
      end
    end

    Thread.abort_on_exception = true
    loop do

      if node_id

        # register node
        Sessions::Node.register(node_id)

        # watch for assigned sessions
        client_ids = Sessions::Node.sessions_by(node_id)
      else
        client_ids = sessions
      end

      client_ids.each do |client_id|

        # connection already open, ignore
        next if @@client_threads[client_id]

        # get current user
        session_data = Sessions.get(client_id)
        next if session_data.blank?
        next if session_data[:user].blank?
        next if session_data[:user]['id'].blank?

        user = User.lookup(id: session_data[:user]['id'])
        next if user.blank?

        # start client thread
        next if @@client_threads[client_id].present?

        @@client_threads[client_id] = true
        @@client_threads[client_id] = Thread.new do
          thread_client(client_id, 0, Time.now.utc, node_id)
          @@client_threads[client_id] = nil
          log('debug', "close client (#{client_id}) thread")
          if ActiveRecord::Base.connection.owner == Thread.current
            ActiveRecord::Base.connection.close
          end
        end
        sleep 1
      end

      sleep 1
    end
  end

=begin

check if thread for client_id is running

  Sessions.thread_client_exists?(client_id)

returns

  thread

=end

  def self.thread_client_exists?(client_id)
    @@client_threads[client_id]
  end

=begin

start client for browser

  Sessions.thread_client(client_id)

returns

  thread

=end

  def self.thread_client(client_id, try_count = 0, try_run_time = Time.now.utc, node_id)
    log('debug', "LOOP #{node_id}.#{client_id} - #{try_count}")
    begin
      Sessions::Client.new(client_id, node_id)
    rescue => e
      log('error', "thread_client #{client_id} exited with error #{e.inspect}")
      log('error', e.backtrace.join("\n  ") )
      sleep 10
      begin
        ActiveRecord::Base.connection_pool.release_connection
      rescue => e
        log('error', "Can't reconnect to database #{e.inspect}")
      end

      try_run_max = 10
      try_count += 1

      # reset error counter if to old
      if try_run_time + ( 60 * 5 ) < Time.now.utc
        try_count = 0
      end
      try_run_time = Time.now.utc

      # restart job again
      if try_run_max > try_count
        thread_client(client_id, try_count, try_run_time, node_id)
      end
      raise "STOP thread_client for client #{node_id}.#{client_id} after #{try_run_max} tries"
    end
    log('debug', "/LOOP #{node_id}.#{client_id} - #{try_count}")
  end

  def self.symbolize_keys(hash)
    hash.each_with_object({}) do |(key, value), result|
      new_key = case key
                when String then key.to_sym
                else key
                end
      new_value = case value
                  when Hash then symbolize_keys(value)
                  else value
                  end
      result[new_key] = new_value
    end
  end

  # we use it in rails and non rails context
  def self.log(level, message)
    if defined?(Rails)
      case level
      when 'debug'
        Rails.logger.debug { message }
      when 'info'
        Rails.logger.info message
      else
        Rails.logger.error message
      end
      return
    end
    puts "#{Time.now.utc.iso8601}:#{level} #{message}" # rubocop:disable Rails/Output
  end
end
