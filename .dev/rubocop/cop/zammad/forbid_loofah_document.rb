# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module RuboCop
  module Cop
    module Zammad
      class ForbidLoofahDocument < Base
        MSG = 'Do not use Loofah.document. Use explicit parser version'.freeze

        def_node_matcher :loofah_document?, <<~PATTERN
          (send (const nil? :Loofah) :document)
        PATTERN

        def on_send(node)
          add_offense(node, message: MSG) if loofah_document?(node)
        end
      end
    end
  end
end
