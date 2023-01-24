# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sessions::Store::Redis
  SESSIONS_KEY = 'sessions'.freeze
  MESSAGES_KEY = 'messages'.freeze
  SPOOL_KEY = 'spool'.freeze
  NODES_KEY = 'nodes'.freeze

  def initialize
    # Only load redis if it is really used.
    require 'redis'
    require 'hiredis'
    @redis = Redis.new(driver: :hiredis)
  end

  def create(client_id, data)
    @redis.set client_session_key(client_id), data
    @redis.sadd? SESSIONS_KEY, client_id
  end

  def sessions
    @redis.smembers SESSIONS_KEY
  end

  def session_exists?(client_id)
    @redis.sismember SESSIONS_KEY, client_id
  end

  def destroy(client_id)
    @redis.srem? SESSIONS_KEY, client_id
    @redis.del client_session_key(client_id)
    @redis.del client_messages_key(client_id)
  end

  def set(client_id, data)
    @redis.set client_session_key(client_id), data.to_json
  end

  def get(client_id)
    data = nil

    # if only session is missing, then it's an error behavior
    session = @redis.get client_session_key(client_id)
    if !session
      destroy(client_id)
      Sessions.log('error', "missing session value for '#{client_id}', removing session.")
      return
    end

    data_json = JSON.parse(session)
    if data_json
      data        = Sessions.symbolize_keys(data_json)
      data[:user] = data_json['user'] # for compat. reasons
    end

    data
  end

  def send_data(client_id, data)
    key = client_messages_key(client_id)
    key_is_new = !@redis.exists?(key)
    @redis.rpush(key, data.to_json).positive?.tap do
      # Make sure message keys are cleaned up even if they are no longer listed in 'sessions'.
      @redis.expire(key, 1.hour) if key_is_new
    end
  end

  def queue(client_id)
    data = []
    while (item = @redis.lpop(client_messages_key(client_id)))
      data.push JSON.parse(item)
    end
    data
  end

  def cleanup
    clear_spool
    clear_sessions
    clear_messages
    true
  end

  def add_to_spool(data)
    @redis.rpush SPOOL_KEY, data.to_json
  end

  def each_spool()
    @redis.lrange(SPOOL_KEY, 0, -1).each do |message|
      yield message, nil
    end
  end

  def remove_from_spool(message, _entry)
    @redis.lrem SPOOL_KEY, 1, message
  end

  def clear_spool
    @redis.del SPOOL_KEY
  end

  def clear_sessions
    @redis.keys("#{SESSIONS_KEY}/*").each do |key|
      @redis.del key
    end
    @redis.del SESSIONS_KEY
  end

  def clear_messages
    @redis.keys("#{MESSAGES_KEY}/*").each do |key|
      @redis.del key
    end
  end

  ### Node-specific methods ###

  def clear_nodes
    @redis.keys("#{NODES_KEY}/*").each do |key|
      @redis.del key
    end
    @redis.del NODES_KEY
  end

  def nodes
    nodes = []
    @redis.smembers(NODES_KEY).each do |node_id|
      content = @redis.get(node_key(node_id))
      if content
        data = JSON.parse(content)
        nodes.push data
      end
    end
    nodes
  end

  def add_node(node_id, data)
    @redis.set node_key(node_id), data.to_json
    @redis.sadd? NODES_KEY, node_id
  end

  def each_node_session(&)
    @redis.smembers(NODES_KEY).each do |node_id|
      each_session_by_node(node_id, &)
    end
  end

  def create_node_session(node_id, client_id, data)
    @redis.set node_client_session_key(node_id, client_id), data.to_json
    @redis.sadd? node_sessions_key(node_id), client_id
  end

  def each_session_by_node(node_id)
    @redis.smembers(node_sessions_key(node_id)).each do |client_id|
      content = @redis.get(node_client_session_key(node_id, client_id))
      if content
        data = JSON.parse(content)
        yield data
      end
    end
  end

  protected

  def client_session_key(client_id)
    "#{SESSIONS_KEY}/#{client_id}"
  end

  def client_messages_key(client_id)
    "#{MESSAGES_KEY}/#{client_id}"
  end

  def node_key(node_id)
    "#{NODES_KEY}/#{node_id}"
  end

  def node_sessions_key(node_id)
    "#{node_key(node_id)}/sessions"
  end

  def node_client_session_key(node_id, client_id)
    "#{node_sessions_key(node_id)}/#{client_id}"
  end
end
