# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'puma/minissl'

# Puma 8.0.3 raises IO::EAGAINWaitReadable for an incomplete TLS record also with exception: false.
#   Action Cable reads like that and closes the websocket of a message longer than 4096 bytes on the
#   raise. Only the test app servers terminate TLS in Puma (puma/puma#4173).
module PumaMiniSSLReadNonblock
  def read_nonblock(size, *, exception: true)
    super
  rescue IO::WaitReadable
    raise if exception

    :wait_readable
  end
end

Puma::MiniSSL::Socket.prepend(PumaMiniSSLReadNonblock)
