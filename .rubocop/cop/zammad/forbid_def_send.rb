# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module RuboCop
  module Cop
    module Zammad
      class ForbidDefSend < Base
        MSG = <<~ERROR_MESSAGE.freeze
          Please avoid 'def send' if possible, as it overlaps with Ruby's built-in 'send' method. Consider alternatives such as 'deliver' instead.
        ERROR_MESSAGE

        def on_defs(node)
          children = node.children
          add_offense(node) if children.first.type == :self && children[1] == :send
        end

        def on_def(node)
          return if node.operator_method?

          add_offense(node) if node.method_name.eql?(:send)
        end
      end
    end
  end
end
