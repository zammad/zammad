# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module RuboCop
  module Cop
    module Zammad
      class ForbidDefaultScope < Base
        MSG = <<~ERROR_MESSAGE.freeze
          In zammad it is only allowed to set very simple default scopes which order the rows by default. E.g.

          default_scope { order(:id) }

          Any other complex forms of this are not allowed anymore. For more information see:

          https://rails-bestpractices.com/posts/2013/06/15/default_scope-is-evil/
        ERROR_MESSAGE

        def_node_matcher :default_scope?, <<-PATTERN
          $(block $(:send _ :default_scope) ...)
        PATTERN

        SENDS = %w[default_scope order].freeze

        def on_block(node)
          return if !default_scope?(node)
          return if node.to_s.scan(%r{send\snil\s:(.+)\b}).flatten.all? { |name| SENDS.include?(name) }

          add_offense(node)
        end
      end
    end
  end
end
