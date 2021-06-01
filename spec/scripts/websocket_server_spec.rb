# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# rubocop:disable RSpec/DescribeClass

require 'spec_helper'
require 'support/script_helper'
require 'timeout'

describe 'websocket-server', type: :script do
  # Why not Rails.root.join here?
  # Because it's not avaialable in this spec (no 'rails_helper' = faster start-up)
  let(:app_root)   { File.expand_path('../..', __dir__) }
  let(:ws_server)  { File.expand_path('script/websocket-server.rb', app_root) }
  let(:pidfile)    { File.expand_path('tmp/pids/websocket.pid', app_root) }
  let(:output_log) { File.expand_path('log/websocket-server_out.log', app_root) }
  let(:error_log)  { File.expand_path('log/websocket-server_err.log', app_root) }

  context 'with IPv6 bind address (via -b option)', if: has_ipv6? do
    # This error is raised for invalid bind addresses
    let(:error_msg) { "`start_tcp_server': no acceptor" }
    let(:ipv6_addr) { '::1/128' }
    # Prevent port assignment conflicts during parallel test execution
    let(:port)      { rand(60_000..65_000) }

    # Flush logs
    before do
      File.write(output_log, '')
      File.write(error_log, '')
    end

    it 'starts up successfully' do

      system("RAILS_ENV=test #{ws_server} start -db #{ipv6_addr} -p #{port} >/dev/null 2>&1")

      # Wait for daemon to start
      Timeout.timeout(20, Timeout::Error, 'WebSocket Server startup timed out') do
        loop { break if File.size(output_log) + File.size(error_log) > 0 }
      end

      expect(File.read(error_log)).not_to include(error_msg)
    ensure
      system("#{ws_server} stop >/dev/null 2>&1") if File.exist?(pidfile)

    end
  end
end

# rubocop:enable RSpec/DescribeClass
