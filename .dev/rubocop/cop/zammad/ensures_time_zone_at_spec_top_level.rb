# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module RuboCop
  module Cop
    module Zammad
      # This spec ensures that time zones in system specs are set at the top level only.
      # The problem is if time zone changes in the middle of the spec, browser does not pick it up.
      # This leads to confusing issues when whole file vs specific portion are executed.
      #
      # Non-system tests are ignored. Timezone in pure RSPec tests can be set at any moment.
      #
      # @example
      #   # bad
      #   RSpec.describe 'Test', type: :system do
      #     it 'is fine', time_zone: 'Europe/London' do
      #       example
      #     end
      #   end
      #
      #   # good
      #   RSpec.describe 'Test', type: :system, time_zone: 'Europe/London' do
      #     it 'is fine' do
      #       example
      #     end
      #   end
      class EnsuresTimeZoneAtSpecTopLevel < Base
        def_node_matcher :is_rspec_block_with_time_zone?, <<-PATTERN
          $(send _ {:describe :context :it :shared_examples} (_ ...) (hash <(pair (sym :time_zone) (str...))...>))
        PATTERN

        def_node_matcher :is_system_type?, <<-PATTERN
          $(block (send (const _ :RSpec) :describe (_ ...)  (hash <(pair (sym :type) (sym :system))...>)...)...)
        PATTERN

        def_node_matcher :is_rspec_top_level_block?, <<-PATTERN
          $(send (const _ :RSpec) :describe...)
        PATTERN

        MSG = 'RSpec system tests (aka Capybara) should set custom time zones at top level only'.freeze

        def on_send(node)
          return if !is_rspec_block_with_time_zone?(node)
          return if is_rspec_top_level_block?(node)
          return if !in_system_spec?(node)

          add_offense(node)
        end

        def in_system_spec?(node)
          top_parent = node.parent
          loop do
            break if !top_parent
            return true if is_system_type?(top_parent)

            top_parent = top_parent.parent
          end

          false
        end
      end
    end
  end
end
