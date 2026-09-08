# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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
    if (user = session_user(session))
      new_session_data = {
        'id' => user.id,
      }

      # Carried along because the prerequisites are re-checked while the session is served, and
      #   the session record this was read from is not available there: a session an admin
      #   switched to is exempt from maintenance mode, and nothing else tells it apart later.
      if session.data['switched_from_user_id'].present?
        new_session_data['switched_from_user_id'] = session.data['switched_from_user_id']
      end
    end

    # create new session
    if @client
      @client[:session] = new_session_data
      Sessions.create(@client_id, new_session_data, { type: 'websocket' })
    else
      Sessions.create(@client_id, new_session_data, { type: 'ajax' })
    end

    # send app version
    Sessions.send(@client_id, app_version)

    false
  end

  private

  # The prerequisites of the HTTP transport must be applied here as well (see
  #   ApplicationController::Authenticates#authentication_check_prerequesits), otherwise a
  #   session that was retained across a deactivation would stay authorized on this transport.
  def session_user(session)
    return if session&.data.blank?
    return if session.data['user_id'].blank?

    user = User.find_by(id: session.data['user_id'])
    return if !user&.active?
    return if Auth::SwitchedSession.revoked?(session.data['switched_from_user_id'])
    return if Auth::MaintenanceMode.blocks?(user, switched_from_user_id: session.data['switched_from_user_id'])

    user
  end

end
