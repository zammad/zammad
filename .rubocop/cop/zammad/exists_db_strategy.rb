# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module RuboCop
  module Cop
    module Zammad
      class ExistsDbStrategy < Base
        def_node_matcher :migration_execute?, <<-PATTERN
          $(send {(const (const _ :ObjectManager ) :Attribute) (... :described_class)} :migration_execute)
        PATTERN

        def_node_matcher :create_attribute?, <<-PATTERN
          $(send _ :create_attribute ...)
        PATTERN

        def_node_matcher :is_block?, <<-PATTERN
          $(block ...)
        PATTERN

        def_node_matcher :has_reset?, <<-PATTERN
          $(send _ {:describe :context :it :shared_examples} (_ ...) (hash <(pair (sym :db_strategy) (sym {:reset :reset_all})) ...>  ))
        PATTERN

        MSG = 'Add a `db_strategy: :reset` to your context/decribe when you are creating object manager attributes!'.freeze

        def on_send(node)
          return if !migration_execute?(node) && !create_attribute?(node)

          reset = false
          node_parent = node.parent
          until node_parent.nil?
            if is_block?(node_parent) && has_reset?(node_parent.children[0])
              reset = true
              break
            end
            node_parent = node_parent.parent
          end

          return if reset

          add_offense(node)
        end
      end
    end
  end
end
