class Sessions::Event::Login < Sessions::Event::Base

  def run

    # get user_id
    if @payload && @payload['session_id']
      if @is_web_socket
        ActiveRecord::Base.establish_connection
      end
      session = ActiveRecord::SessionStore::Session.find_by(session_id: @payload['session_id'])
      if @is_web_socket
        ActiveRecord::Base.remove_connection
      end
    end

    if session && session.data && session.data['user_id']
      new_session_data = { 'id' => session.data['user_id'] }
    else
      new_session_data = {}
    end

    if @clients[@client_id]
      @clients[@client_id][:session] = new_session_data
      Sessions.create(@client_id, new_session_data, { type: 'websocket' })
    else
      Sessions.create(@client_id, new_session_data, { type: 'ajax' })
    end

    false
  end

end
