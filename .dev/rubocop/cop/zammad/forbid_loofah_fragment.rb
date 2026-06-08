# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module RuboCop
  module Cop
    module Zammad
      class ForbidLoofahFragment < Base
        MSG = 'Do not use Loofah.fragment. Use explicit parser version'.freeze

        def_node_matcher :loofah_fragment?, <<~PATTERN
          (send (const nil? :Loofah) :fragment)
        PATTERN

        def on_send(node)
          add_offense(node, message: MSG) if loofah_fragment?(node)
        end
      end
    end
  end
end
