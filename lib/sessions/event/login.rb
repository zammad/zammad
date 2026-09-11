# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Sessions::Event::Login < Sessions::Event::Base
  database_connection_required

=begin

Event module to start websocket session for new client connections.

The user is resolved from the session cookie sent with the websocket handshake,
in the same way ApplicationCable::Connection does it. Any session identifier
supplied in the event payload is ignored.

Like ActionCable, the cookie is only trusted when the handshake Origin header
matches the configured Zammad origin (or a localhost origin). This prevents a
page on a sibling origin, which browsers still send the SameSite=Lax session
cookie to, from adopting the user's websocket session.

To execute this manually, just paste the following into the browser console

  App.WebSocket.send({event:'login'})

=end

  # Support for local development and test setups, in the same way as
  # config/initializers/zzz_action_cable_preferences.rb does it.
  LOCALHOST_ORIGIN = %r{\Ahttps?://localhost:\d+\z}

  def run
    app_version = AppVersion.event_data

    new_session_data = {}
    session = session_from_cookie
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

  def session_from_cookie
    return if !origin_allowed?

    public_session_id = session_cookie_value
    return if public_session_id.blank?

    private_session_id = Rack::Session::SessionId.new(public_session_id).private_id
    ActiveRecord::SessionStore::Session.find_by(session_id: private_session_id)
  end

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

  # Browsers always send the Origin header on websocket handshakes, so a missing
  # or foreign origin means the cookie must not be used to authenticate.
  def origin_allowed?
    request_origin = header_value('Origin')
    return false if request_origin.blank?
    return true if LOCALHOST_ORIGIN.match?(request_origin)

    request_origin.casecmp?(zammad_origin)
  end

  def zammad_origin
    "#{Setting.get('http_type')}://#{Setting.get('fqdn')}"
  end

  def session_cookie_value
    cookie_header = header_value('Cookie')
    return if cookie_header.blank?

    Rack::Utils.parse_cookies_header(cookie_header)[Zammad::Application::Initializer::SessionStore::SESSION_KEY]
  end

  # Header names are looked up case-insensitively, since proxies may not preserve their casing.
  def header_value(name)
    return if @headers.blank?

    @headers.find { |key, _| key.to_s.casecmp?(name) }&.last.presence
  end

end
