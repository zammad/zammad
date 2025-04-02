# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module RuboCop
  module Cop
    module Zammad
      #
      #
      # @example
      #   # bad
      #   Ticket.where(state: open_states).order(...)
      #
      #   # good
      #   Ticket.where(state: open_states).reorder(...)
      #   default_scope { order(:prio, :id) }
      #   scope :sorted, -> { order(position: :asc) }

      class ActiveRecordReorder < Base
        extend AutoCorrector

        def_node_matcher :active_record_order_call?, <<-PATTERN
          $(send _ {:order} _ ...)
        PATTERN

        def_node_matcher :default_scope_call?, <<-PATTERN
          $(send _ {:default_scope} ...)
        PATTERN

        def_node_matcher :scope_call?, <<-PATTERN
          $(send _ {:scope} sym ...)
        PATTERN

        MSG = "Prefer 'reorder' over 'order' to prevent issues with default ordering.".freeze

        def on_send(node)
          return if active_record_order_call?(node).nil?
          return if default_scope_call?(node.parent&.children&.first)
          return if scope_call?(node.parent&.parent)

          add_offense(node) do |corrector|
            corrector.replace(node.loc.selector, :reorder)
          end
        end
      end
    end
  end
end
