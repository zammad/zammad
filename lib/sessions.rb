# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Sessions

  @store = case Rails.application.config.websocket_session_store
           when :redis then Sessions::Store::Redis.new
           else Sessions::Store::File.new
           end

=begin

start new session

  Sessions.create(client_id, session_data, { type: 'websocket' })

returns

  true|false

=end

  def self.create(client_id, session, meta)
    # collect session data
    meta[:last_ping] = Time.now.utc.to_i
    data = {
      user: session,
      meta: meta,
    }
    content = data.to_json

    @store.create(client_id, content)

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
    @store.sessions
  end

=begin

list of all session

  Sessions.session_exists?(client_id)

returns

  true|false

=end

  def self.session_exists?(client_id)
    @store.session_exists?(client_id)
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
    @store.destroy(client_id)
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
      if !client[:meta] || !client[:meta][:last_ping] || (client[:meta][:last_ping].to_i + idle_time_in_sec) < Time.now.utc.to_i
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

    data[:meta][:last_ping] = Time.now.utc.to_i
    @store.set(client_id, data)
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
    @store.get client_id
  end

=begin

send message to client

  Sessions.send(client_id_of_recipient, data)

returns

  true|false

=end

  def self.send(client_id, data) # rubocop:disable Zammad/ForbidDefSend
    @store.send_data(client_id, data)
  end

=begin

send message to recipient client

  Sessions.send_to(user_id, data)

e. g.

  Sessions.send_to(user_id, {
    event: 'session_takeover',
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
    @store.queue(client_id)
  end

=begin

remove all session and spool messages

  Sessions.cleanup

=end

  def self.cleanup
    @store.cleanup
  end

=begin

Zammad previously used a spooling mechanism for session mechanism.
The code to clean-up such data is still here, even though the mechanism
itself was removed in the meantime.

  Sessions.spool_delete

=end

  def self.spool_delete
    @store.clear_spool
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
      log('error', e.backtrace.join("\n  "))
      sleep 10

      try_run_max = 10
      try_count += 1

      # reset error counter if to old
      if try_run_time + (60 * 5) < Time.now.utc
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

  # This is a shorthand to simulate the old Sessions.jobs behavior using the new BackgroundServices worker
  # This should be used for debugging only
  # For production, please run BackgroundServices
  def self.jobs
    BackgroundServices::Service::ProcessSessionsJobs
      .pre_run

    BackgroundServices::Service::ProcessSessionsJobs
      .new(manager: nil)
      .launch
  end
end
