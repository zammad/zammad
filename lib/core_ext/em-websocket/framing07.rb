# encoding: BINARY

# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

# Monkey patch for frozen literal string warning

require 'em-websocket'

$VERBOSE = nil

# rubocop:disable Lint/MissingCopEnableDirective
# rubocop:disable Zammad/DetectTranslatableString
# rubocop:disable Style/StringLiterals

module EventMachine
  module WebSocket
    module Framing07

      def send_frame(frame_type, application_data)
        debug [:sending_frame, frame_type, application_data]

        if @state == :closing && data_frame?(frame_type)
          raise WebSocketError, "Cannot send data frame since connection is closing"
        end

        frame = +''

        opcode = type_to_opcode(frame_type)
        byte1 = opcode | 0b10000000 # fin bit set, rsv1-3 are 0
        frame << byte1

        length = application_data.size
        if length <= 125
          byte2 = length # since rsv4 is 0
          frame << byte2
        elsif length < 65_536 # write 2 byte length
          frame << 126
          frame << [length].pack('n')
        else # write 8 byte length
          frame << 127
          frame << [length >> 32, length & 0xFFFFFFFF].pack("NN")
        end

        frame << application_data

        @connection.send_data(frame)
      end
    end
  end
end
