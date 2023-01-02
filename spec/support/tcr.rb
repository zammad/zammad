# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'tcr'

TCR.configure do |config|
  config.cassette_library_dir = 'test/data/tcr_cassettes'
  config.hook_tcp_ports = [389] # LDAP
  config.format = 'yaml'
end

# TODO: tcr 0.22 does not seem to be compatible with Ruby 3, as it tries to perform a legacy call to
#   Socket.tcp(host, port, *socket_opts), where it should be **socket_opts. Work around this by omitting that part.
class Socket
  class << self

    # def tcp(host, port, *socket_opts)
    #   if TCR.configuration.hook_tcp_ports.include?(port)
    #     TCR::RecordableTCPSocket.new(host, port, TCR.cassette)
    #   else
    #     real_tcp(host, port, *socket_opts)
    #   end
    # end

    def tcp(host, port, ...)
      if TCR.configuration.hook_tcp_ports.include?(port)
        TCR::RecordableTCPSocket.new(host, port, TCR.cassette)
      else
        real_tcp(host, port, ...)
      end
    end
  end
end
