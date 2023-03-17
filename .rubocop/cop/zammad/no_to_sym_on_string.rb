# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module RuboCop
  module Cop
    module Zammad
      # This cop is used to identify usages of `.to_sym` on Strings and
      # changes them to use the `:` prefix instead.
      #
      # @example
      #   # bad
      #   "a-Symbol".to_sym
      #   'a-Symbol'.to_sym
      #   "a-#{'Symbol'}".to_sym
      #
      #   # good
      #   :"a-Symbol"
      #   :'a-Symbol'
      #   :"a-#{'Symbol'}"
      class NoToSymOnString < Base
        extend AutoCorrector

        def_node_matcher :to_sym?, <<-PATTERN
          {
            $(send (str ...) :to_sym ...)
            $(send (dstr ...) :to_sym ...)
          }
        PATTERN

        MSG = "Don't use `.to_sym` on String. Prefer `:` prefix instead.".freeze

        def on_send(node)
          result = *to_sym?(node)
          return if result.empty?

          add_offense(node, message: MSG) do |corrector|
            corrector.replace(node, ":#{result.first.source}")
          end
        end
      end
    end
  end
end
