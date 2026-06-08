# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Monkey patch for frozen literal string warning

require 'em-websocket'

$VERBOSE = nil

module EventMachine
  module WebSocket
    class MaskedString < String
      def getbytes(start_index, count)
        data = +''
        data.force_encoding('ASCII-8BIT') if data.respond_to?(:force_encoding)
        count.times do |i|
          data << getbyte(start_index + i)
        end
        data
      end
    end
  end
end
