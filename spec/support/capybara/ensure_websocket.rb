# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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
