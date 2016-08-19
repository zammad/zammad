class Sessions::Event::Base

  def initialize(params)
    params.each { |key, value|
      instance_variable_set "@#{key}", value
    }

    @is_web_socket = false
    return if !@clients[@client_id]
    @is_web_socket = true
  end

  def websocket_send(recipient_client_id, data)
    msg = if data.class != Array
            "[#{data.to_json}]"
          else
            data.to_json
          end
    if @clients[recipient_client_id]
      log 'debug', "ws send #{msg}", recipient_client_id
      @clients[recipient_client_id][:websocket].send(msg)
    else
      log 'debug', "fs send #{msg}", recipient_client_id
      Sessions.send(recipient_client_id, data)
    end
  end

  def valid_session?
    if !@session
      error = {
        event: 'error',
        data: {
          state: 'no_session',
        },
      }
      Sessions.send(@client_id, error)
      return
    end
    if !@session['id']
      error = {
        event: 'error',
        data: {
          state: 'no_session_user_id',
        },
      }
      Sessions.send(@client_id, error)
      return
    end
    true
  end

  def permission_check(key, event)
    if !@session
      error = {
        event: "#{event}_error",
        data: {
          state: 'no_session',
        },
      }
      Sessions.send(@client_id, error)
      return
    end
    if !@session['id']
      error = {
        event: "#{event}_error",
        data: {
          state: 'no_session_user_id',
        },
      }
      Sessions.send(@client_id, error)
      return
    end
    user = User.lookup(id: @session['id'])
    if !user
      error = {
        event: "#{event}_error",
        data: {
          state: 'no_such_user',
        },
      }
      Sessions.send(@client_id, error)
      return
    end
    if !user.permissions?(key)
      error = {
        event: "#{event}_error",
        data: {
          state: 'no_permission',
        },
      }
      Sessions.send(@client_id, error)
      return
    end
    true
  end

  def log(level, data, client_id = nil)
    if !@options[:v]
      return if level == 'debug'
    end
    if !client_id
      client_id = @client_id
    end
    # rubocop:disable Rails/Output
    puts "#{Time.now.utc.iso8601}:client(#{client_id}) #{data}"
    #puts "#{Time.now.utc.iso8601}:#{ level }:client(#{ client_id }) #{ data }"
    # rubocop:enable Rails/Output
  end

  def destroy
  end

end
