# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module RuboCop
  module Cop
    module Zammad
      class MigrationSchedulerLastRun < Base
        MSG = "Make sure to set a last_run parameter so the migration will not fail, if it is migrated while the instance is running.\n e.g. last_run: Time.zone.now".freeze

        def_node_matcher :scheduler_last_run_missing?, <<-PATTERN
          $(send (const _ :Scheduler) {:create_if_not_exists :create_or_update} ...)
        PATTERN

        def on_send(node)
          return if !scheduler_last_run_missing?(node)

          params = node.children[2].keys.map(&:value)
          return if params.include?(:last_run)

          add_offense(node)
        end
      end
    end
  end
end
