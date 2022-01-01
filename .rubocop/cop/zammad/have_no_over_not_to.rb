# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'capybara/rspec/matchers'

module RuboCop
  module Cop
    module Zammad
      # This cop is used to identify usages of `have_*` RSpec matcher together with `not_to`.
      # `have_no_*` with `to` is preferred
      #
      # @example
      #   # bad
      #   expect(page).not_to have_css('#elem')
      #
      #   # good
      #   expect(page).to have_no_css('#elem')
      class HaveNoOverNotTo < Base
        extend AutoCorrector

        MSG = 'Prefer `.to %<replacement>s` over `.not_to %<original>s`.'.freeze

        def_node_matcher :on_have_not_no, '(send (send nil? :expect ...) :not_to (send nil? #matcher_to_replace? ...))'

        def matcher_to_replace?(matcher_name)
          have_not_no?(matcher_name) && capybara_matcher?(matcher_name)
        end

        def have_not_no?(matcher_name)  # rubocop:disable Naming/PredicateName
          matcher_name.match?(%r{^have_(?!no)})
        end

        def capybara_matcher?(matcher_name)
          Capybara::RSpecMatchers.instance_methods.include?(matcher_name)
        end

        def on_send(node)
          on_have_not_no(node) do
            add_offense(node, message: message(node)) do |corrector|
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
          original_matcher(node).to_s.sub 'have_', 'have_no_'
        end

        def message(node)
          format(MSG, replacement: alternative_matcher(node), original: original_matcher(node))
        end
      end
    end
  end
end
