# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module RuboCop
  module Cop
    module Zammad
      # Rails model callbacks that trigger GraphQL subscriptions must do that only in commit callbacks,
      # as the handlers live in other processes and do not have access to the current transaction.
      #
      # @example
      #   # bad
      #   after_create  :trigger_subscriptions
      #   after_update  :trigger_subscriptions
      #   after_save    :trigger_subscriptions
      #   after_destroy :trigger_subscriptions
      #
      #   # good
      #   after_create_commit  :trigger_subscriptions
      #   after_update_commit  :trigger_subscriptions
      #   after_save_commit    :trigger_subscriptions
      #   after_destroy_commit :trigger_subscriptions

      class TriggerFromCommitHooks < Base
        extend AutoCorrector

        def_node_matcher :non_commit_callback?, <<-PATTERN
          $(send _ {:after_create :after_update :after_save :after_destroy} (sym _))
        PATTERN

        MSG = 'Trigger GraphQL subscriptions only from commit hooks to ensure the data is available in other processes.'.freeze

        def on_send(node)
          return if non_commit_callback?(node).nil?
          return if !trigger_callback?(node)

          add_offense(node) do |corrector|
            corrector.replace(node.loc.selector, correct_callback(node.children[1]))
          end
        end

        def trigger_callback?(node)
          node.children[2].value.start_with? 'trigger'
        end

        def correct_callback(callback)
          "#{callback}_commit"
        end
      end
    end
  end
end
