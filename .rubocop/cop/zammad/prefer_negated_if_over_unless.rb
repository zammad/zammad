# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module RuboCop
  module Cop
    module Zammad
      # This cop is used to identify usages of `unless` conditionals
      #
      # @example
      #   # bad
      #   unless statement
      #   return unless statement
      #
      #   # good
      #   if !statement
      #   return if !statement
      class PreferNegatedIfOverUnless < Base
        include ConfigurableEnforcedStyle
        include NegativeConditional
        extend AutoCorrector

        MSG = 'Favor `if !foobar` over `unless foobar` for ' \
              'negative conditions.'.freeze

        def on_if(node)
          return if !node.unless?

          add_offense(node, message: MSG)
        end
      end
    end
  end
end
