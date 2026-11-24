# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Sessions::Store::Redis
  # Scoped per environment, so that a development stack and a test run do not
  #   share their session bookkeeping - the same reason Sessions::Store::File
  #   keeps its directories apart. Production keeps the plain keys, so that an
  #   upgrade does not orphan the existing ones.
  KEY_SUFFIX = (Rails.env.production? ? '' : "_#{Rails.env}").freeze

  SESSIONS_KEY = "sessions#{KEY_SUFFIX}".freeze
  MESSAGES_KEY = "messages#{KEY_SUFFIX}".freeze
  SPOOL_KEY = "spool#{KEY_SUFFIX}".freeze
  NODES_KEY = "nodes#{KEY_SUFFIX}".freeze

  GET_MANY_SLICE_SIZE = 1000
  PIPELINE_SLICE_SIZE = 1000

  def initialize
    @redis = Zammad::Service::Redis.new
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
    @redis.del client_messages_key(client_id)

    # single sessions worker
    @redis.srem? SESSIONS_KEY, client_id
    @redis.del client_session_key(client_id)

    # forked sessions workers
    @redis.scan_each(match: node_client_session_key('*', client_id), count: 1) do |key|
      captures = key.match(%r{#{NODES_KEY}/([^/]+)/sessions/#{client_id}})

      if captures
        node_id = captures[1]

        @redis.del key
        @redis.srem? node_sessions_key(node_id), client_id
      end

      break
    end
  end

  def set(client_id, data)
    @redis.set client_session_key(client_id), data.to_json
  end

  def get(client_id)
    parse_session(client_id, @redis.get(client_session_key(client_id)))
  end

  def get_many(client_ids)
    client_ids.each_slice(GET_MANY_SLICE_SIZE).with_object({}) do |slice, result|
      values = @redis.mget(slice.map { client_session_key(it) })

      slice.zip(values) do |client_id, session|
        data = parse_session(client_id, session)
        result[client_id] = data if data
      end
    end
  end

  def send_data(client_id, data)
    key = client_messages_key(client_id)
    key_is_new = !@redis.exists?(key)
    @redis.rpush(key, data.to_json).positive?.tap do
      # Make sure message keys are cleaned up even if they are no longer listed in 'sessions'.
      @redis.expire(key, 1.hour) if key_is_new
    end
  end

  def send_data_many(entries)
    payloads = {}.compare_by_identity

    entries.each_slice(PIPELINE_SLICE_SIZE) do |slice|
      keys = slice.map { |client_id, _data| client_messages_key(client_id) }

      lengths = @redis.pipelined do |pipeline|
        slice.each_with_index do |(_client_id, data), index|
          pipeline.rpush(keys[index], payloads[data] ||= data.to_json)
        end
      end

      # A length of 1 means the push created the key. Like #send_data, only a new key gets the expiry,
      #   so that a queue nobody reads is still dropped an hour after it was created. It is set per slice,
      #   so that a connection lost in between leaves at most the new queues of one slice without it.
      new_keys = keys.zip(lengths).filter_map { |key, length| key if length == 1 }
      next if new_keys.empty?

      @redis.pipelined do |pipeline|
        new_keys.each { pipeline.expire(it, 1.hour) }
      end
    end
  end

  def queue(client_id)
    data = []
    while (item = @redis.lpop(client_messages_key(client_id)))
      data.push JSON.parse(item)
    end
    data
  end

  def clear_queue(client_id)
    @redis.del client_messages_key(client_id)
  end

  def cleanup
    clear_spool
    clear_sessions
    clear_messages
    true
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

  def parse_session(client_id, session)
    data = nil

    # if only session is missing, then it's an error behavior
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
