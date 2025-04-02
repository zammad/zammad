# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module RuboCop
  module Cop
    module Zammad
      #
      #
      # @example
      #   # bad
      #   Faker::Number.number(...)
      #   Faker::Name.first_name
      #   Faker::Date.between(from: Date.parse("2022-01-01"), to: Date.parse("2024-01-01"))
      #   Faker::Time.between(from: Date.parse("2022-01-01"), to: Date.parse("2024-01-01"))
      #
      #   # good
      #   Faker::Number.unique.number(...)
      #   Faker::Name.unique.first_name
      #   Faker::Date.unique.between(from: Date.parse("2022-01-01"), to: Date.parse("2024-01-01"))
      #   Faker::Time.unique.between(from: Date.parse("2022-01-01"), to: Date.parse("2024-01-01"))

      class FakerUnique < Base
        extend AutoCorrector

        def_node_matcher :faker_call?, <<-PATTERN
          $(send (const (const _ :Faker) {:Name :Number :Date :Time}) _ ...)
        PATTERN

        MSG = 'Always use Faker::*::.unique to prevent race conditions in tests.'.freeze

        def on_send(node)
          return if faker_call?(node).nil?

          method = node.children[1]
          return if method.name == 'unique'

          add_offense(node) do |corrector|
            corrector.replace(node.loc.selector, "unique.#{method.name}")
          end
        end
      end
    end
  end
end
