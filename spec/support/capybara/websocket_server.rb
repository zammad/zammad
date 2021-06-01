# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.configure do |config|
  config.around(:each, type: :system) do |example|

    server_required = example.metadata.fetch(:websocket, true)

    if server_required
      websocket_server = Thread.new do
        WebsocketServer.run(
          p: ENV['WS_PORT'] || 6042,
          b: '0.0.0.0',
          s: false,
          v: false,
          d: false,
        )
      end
    end

    example.run

    next if !server_required

    # returns immediately and thread may be still shutting down
    EventMachine.stop_event_loop

    # give thread time to terminate
    sleep 0.01 while websocket_server.status
  end
end
