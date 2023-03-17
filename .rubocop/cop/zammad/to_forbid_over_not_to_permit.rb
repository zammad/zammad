# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'capybara/rspec/matchers'

module RuboCop
  module Cop
    module Zammad
      # Policy specs using ".not_to permit_actions" will lead to presumably false results,
      #   as that matches when only one of the listed actions is forbidden. Instead,
      #   use the simpler ".to forbid_actions" which ensures all actions are forbidden.
      #
      # @example
      #   # bad
      #   expect(page).not_to permit(:action)
      #
      #   # good
      #   expect(page).to forbid(:action)
      class ToForbidOverNotToPermit < Base
        extend AutoCorrector

        MSG = 'Prefer `.to forbid_action[s]` over `.not_to permit_action[s]`.'.freeze

        def_node_matcher :on_not_to_permit, '(send (send nil? {:expect :is_expected} {_ ...}) :not_to (send nil? {:permit_action :permit_actions} ...))'

        def on_send(node)
          on_not_to_permit(node) do
            add_offense(node, message: MSG) do |corrector|
              corrector.replace(original_matcher_node(node).loc.selector, alternative_matcher(node))
              corrector.replace(node.loc.selector, 'to')
            end
          end
        end

        def original_matcher_node(node)
          node.children[2]
        end

        def original_matcher(node)
          original_matcher_node(node).method_name
        end

        def alternative_matcher(node)
          original_matcher(node).to_s.sub 'permit_action', 'forbid_action'
        end
      end
    end
  end
end
