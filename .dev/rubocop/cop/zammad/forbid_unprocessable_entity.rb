# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module RuboCop
  module Cop
    module Zammad
      # `Exceptions::UnprocessableEntity` is deprecated and will be removed in Zammad 8.0.
      #   Use `Exceptions::UnprocessableContent` instead.
      #
      # @example
      #   # bad
      #   raise Exceptions::UnprocessableEntity, 'message'
      #   rescue Exceptions::UnprocessableEntity => e
      #
      #   # good
      #   raise Exceptions::UnprocessableContent, 'message'
      #   rescue Exceptions::UnprocessableContent => e
      class ForbidUnprocessableEntity < Base
        extend AutoCorrector

        MSG = 'Use `Exceptions::UnprocessableContent` instead of the deprecated `Exceptions::UnprocessableEntity`.'.freeze

        def_node_matcher :unprocessable_entity?, <<~PATTERN
          (const (const {nil? cbase} :Exceptions) :UnprocessableEntity)
        PATTERN

        def on_const(node)
          return if !unprocessable_entity?(node)

          add_offense(node, message: MSG) do |corrector|
            corrector.replace(node.loc.name, 'UnprocessableContent')
          end
        end
      end
    end
  end
end
