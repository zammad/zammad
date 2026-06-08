# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require_relative 'concerns/can_check_gql_operation'

module RuboCop
  module Cop
    module Zammad
      class GraphqlCsrfSkipVerification < Base
        include CanCheckGqlOperation
        extend AutoCorrector

        MSG = 'Replace `requires_csrf_verification?` method that returns `false` with `skip_csrf_verification!`.'.freeze

        def on_defs(node)
          return if !inside_gql_operation?(node)
          # Check for: def self.requires_csrf_verification?(...) false end
          return if node.method_name != :requires_csrf_verification?
          return if !returns_false?(node.body)

          add_offense(node) do |corrector|
            corrector.replace(node, 'skip_csrf_verification!')
          end
        end

        def on_def(node)
          return if !inside_gql_operation?(node)
          # Check for: def requires_csrf_verification?(...) false end
          return if node.method_name != :requires_csrf_verification?
          return if !returns_false?(node.body)

          add_offense(node) do |corrector|
            corrector.replace(node, 'skip_csrf_verification!')
          end
        end

        private

        def returns_false?(body)
          return false if body.nil?

          # Handle simple case: def requires_csrf_verification?; false; end
          return true if body.type == :false # rubocop:disable Lint/BooleanSymbol

          # Handle multi-statement case: def requires_csrf_verification?; puts "foo"; false; end
          if body.type == :begin
            last_statement = body.children.last
            return last_statement&.type == :false # rubocop:disable Lint/BooleanSymbol
          end

          false
        end
      end
    end
  end
end
