# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sessions::Event::Login < Sessions::Event::Base
  database_connection_required

=begin

Event module to start websocket session for new client connections.

To execute this manually, just paste the following into the browser console

  App.WebSocket.send({event:'login', session_id: '123'})

=end

  def run

    # get user_id
    session = nil

    app_version = AppVersion.event_data

    if @payload && @payload['session_id']
      private_session_id = Rack::Session::SessionId.new(@payload['session_id']).private_id
      session = ActiveRecord::SessionStore::Session.find_by(session_id: private_session_id)
    end

    new_session_data = {}
    if session&.data && session.data['user_id']
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
