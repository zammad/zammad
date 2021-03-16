class Sessions::Store::Redis
  SESSIONS_KEY = "sessions"
  MESSAGES_KEY = "messages"
  SPOOL_KEY = "spool"

  def initialize
    @redis = Redis.new
  end

  def create(client_id, data)
    @redis.set client_session_key(client_id), data
    @redis.sadd SESSIONS_KEY, client_id
  end

  def sessions
    @redis.smembers SESSIONS_KEY
  end

  def session_exists?(client_id)
    @redis.sismember SESSIONS_KEY, client_id
  end

  def destroy(client_id)
    @redis.srem SESSIONS_KEY, client_id
    @redis.del client_session_key(client_id)
    @redis.del client_messages_key(client_id)
  end

  def set(client_id, data)
    @redis.set client_session_key(client_id), data.to_json
  end

  def get(client_id)
    data         = nil

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
    @redis.rpush(client_messages_key(client_id), data.to_json) > 0
  end

  def queue(client_id)
    data  = []
    while item = @redis.lpop(client_messages_key(client_id))
      data.push JSON.parse(item)
    end
    data
  end

  def cleanup
    @redis.flushall
    true
  end

  def add_to_spool(data)
    @redis.rpush SPOOL_KEY, data.to_json
  end

  def each_spool(&block)
    @redis.lrange(SPOOL_KEY, 0, -1).each do |message|
      block.call message
    end
  end

  def remove_from_spool(message)
    @redis.lrem SPOOL_KEY, 1, message
  end

  def clear_spool
    @redis.del SPOOL_KEY
  end

  protected

  def client_session_key(client_id)
    "#{SESSIONS_KEY}/#{client_id}"
  end

  def client_messages_key(client_id)
    "#{MESSAGES_KEY}/#{client_id}"
  end
end