# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module RuboCop
  module Cop
    module Zammad
      class EnforceInModal < Base

        MSG = "Prefer `in_modal` over `within '.modal'`.".freeze

        def on_send(node)

          return if node.method_name != :within

          first_arg = node.arguments.first
          return if first_arg.type != :str
          # Remove quotes
          return if !first_arg.source[1..-2].start_with? '.modal'

          add_offense(node)
        end
      end
    end
  end
end
