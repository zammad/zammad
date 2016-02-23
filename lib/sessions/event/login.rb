class Sessions::Event::Login < Sessions::Event::Base

  def run

    # get user_id
    session = nil
    if @is_web_socket
      ActiveRecord::Base.establish_connection
    end

    app_version = AppVersion.event_data

    if @payload && @payload['session_id']
      session = ActiveRecord::SessionStore::Session.find_by(session_id: @payload['session_id'])
    end

    if @is_web_socket
      ActiveRecord::Base.remove_connection
    end

    new_session_data = {}

    if session && session.data && session.data['user_id']
      new_session_data = {
        'id' => session.data['user_id'],
      }
    end

    # create new session
    if @clients[@client_id]
      @clients[@client_id][:session] = new_session_data
      Sessions.create(@client_id, new_session_data, { type: 'websocket' })
    else
      Sessions.create(@client_id, new_session_data, { type: 'ajax' })
    end

    # send app version
    Sessions.send(@client_id, app_version)

    false
  end

end
