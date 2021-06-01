# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sessions::Event::Base

  def initialize(params)
    params.each do |key, value|
      instance_variable_set "@#{key}", value
    end

    @is_web_socket = false
    return if !@clients[@client_id]

    @is_web_socket = true

    return if !self.class.instance_variable_get(:@database_connection)

    if ActiveRecord::Base.connected?
      @reused_connection = true
    else
      @reused_connection = false
      ActiveRecord::Base.establish_connection
    end
  end

  def self.inherited(subclass)
    super
    subclass.instance_variable_set(:@database_connection, @database_connection)
  end

  def websocket_send(recipient_client_id, data)
    msg = if data.instance_of?(Array)
            data.to_json
          else
            "[#{data.to_json}]"
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
        data:  {
          state: 'no_session',
        },
      }
      Sessions.send(@client_id, error)
      return
    end
    if !@session['id']
      error = {
        event: 'error',
        data:  {
          state: 'no_session_user_id',
        },
      }
      Sessions.send(@client_id, error)
      return
    end
    true
  end

  def current_user_id
    if !@session
      error = {
        event: "#{@event}_error",
        data:  {
          state: 'no_session',
        },
      }
      Sessions.send(@client_id, error)
      return
    end
    if @session['id'].blank?
      error = {
        event: "#{@event}_error",
        data:  {
          state: 'no_session_user_id',
        },
      }
      Sessions.send(@client_id, error)
      return
    end
    @session['id']
  end

  def current_user
    user_id = current_user_id
    return if !user_id

    user = User.find_by(id: user_id)
    if !user
      error = {
        event: "#{event}_error",
        data:  {
          state: 'no_such_user',
        },
      }
      Sessions.send(@client_id, error)
      return
    end
    user
  end

  def remote_ip
    @headers&.fetch('X-Forwarded-For', nil).presence
  end

  def origin
    @headers&.fetch('Origin', nil).presence
  end

  def permission_check(key, event)
    user = current_user
    return if !user

    if !user.permissions?(key)
      error = {
        event: "#{event}_error",
        data:  {
          state: 'no_permission',
        },
      }
      Sessions.send(@client_id, error)
      return
    end
    true
  end

  def log(level, data, client_id = nil)
    return if !@options[:v] && level == 'debug'

    if !client_id
      client_id = @client_id
    end
    # rubocop:disable Rails/Output
    puts "#{Time.now.utc.iso8601}:client(#{client_id}) #{data}"
    #puts "#{Time.now.utc.iso8601}:#{ level }:client(#{ client_id }) #{ data }"
    # rubocop:enable Rails/Output
    #Rails.logger.info "#{Time.now.utc.iso8601}:client(#{client_id}) #{data}"
  end

  def self.database_connection_required
    @database_connection = true
  end

  def destroy
    return if !@is_web_socket
    return if !self.class.instance_variable_get(:@database_connection)
    return if @reused_connection

    ActiveRecord::Base.remove_connection
  end

end
