# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module EnsureWebsocket
  # Ensures that websocket is connected
  #
  # @param timeout [Integer] seconds to wait
  # @param check_if_pinged [Boolean] checks if was pinged to prevent stale connections
  #
  # @yield block to execute between disruptive action (e.g. browser refresh) and action that requires websocket
  def ensure_websocket(timeout: 2.minutes, check_if_pinged: true)
    timestamp = Time.zone.now if check_if_pinged

    yield if block_given?

    wait(timeout).until do
      next if check_if_pinged && !pinged_since?(timestamp)

      connection_open?
    end
  end

  # Waits until the current websocket session is marked as logged-in on the
  #   server. The websocket server registers the session without a user on
  #   connection open (WebsocketServer.onopen) and attaches the user only once
  #   the client's `login` event was processed (Sessions::Event::Login) -
  #   ensure_websocket can pass in between, and pushes sent via
  #   Sessions.broadcast or Sessions.send_to before that silently skip the
  #   session and are lost for good.
  #   Only websocket sessions can satisfy the wait - AJAX (long-polling)
  #   sessions in the list could otherwise do so while the websocket itself
  #   is still unauthenticated.
  #
  # @param user [User] accept only a session of this user
  # @param except [Array<String>] session ids to ignore - after an in-test
  #   reload, pass the session ids captured before the reload: the stale
  #   websocket session stays authenticated in the session store until its
  #   disconnect is processed and could otherwise satisfy the wait while the
  #   new connection is still unauthenticated.
  def wait_for_authenticated_session(user: nil, except: [])
    wait.until do
      Sessions.list.any? do |client_id, session|
        except.exclude?(client_id) &&
          session.dig(:meta, :type) == 'websocket' &&
          session.dig(:user, 'id').present? &&
          (user.nil? || session.dig(:user, 'id').to_i == user.id)
      end
    end
  end

  private

  # Checks if session was active since given time
  #
  # @param timestamp [Time] when session was (re)activated
  # @return [Boolean]
  def pinged_since?(timestamp)
    unix_time = timestamp.to_i

    Sessions
      .list
      .values
      .map  { |elem| elem.dig(:meta, :last_ping) }
      .any? { |elem| elem >= unix_time }
  end

  # Checks if websocket connection is active. Javascript function returns string identifier or empty string
  #
  # @return [Boolean]
  def connection_open?
    page
      .evaluate_script('App.WebSocket.channel()')
      .present?
  end
end

RSpec.configure do |config|
  config.include EnsureWebsocket, type: :system
end
