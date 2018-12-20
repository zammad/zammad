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

    Thread.kill(websocket_server)
  end
end
