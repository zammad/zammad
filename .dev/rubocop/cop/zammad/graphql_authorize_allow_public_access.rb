# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require_relative 'concerns/can_check_gql_operation'

module RuboCop
  module Cop
    module Zammad
      class GraphqlAuthorizeAllowPublicAccess < Base
        include CanCheckGqlOperation
        extend AutoCorrector

        MSG = 'Replace `authorize` method that returns `true` with `allow_public_access!`.'.freeze

        def on_defs(node)
          return if !inside_gql_operation?(node)
          # Check for: def self.authorize(...) true end
          return if node.method_name != :authorize
          return if !returns_true?(node.body)

          add_offense(node) do |corrector|
            corrector.replace(node, 'allow_public_access!')
          end
        end

        def on_def(node)
          return if !inside_gql_operation?(node)
          # Check for: def authorize(...) true end
          return if node.method_name != :authorize
          return if !returns_true?(node.body)

          add_offense(node) do |corrector|
            corrector.replace(node, 'allow_public_access!')
          end
        end

        private

        def returns_true?(body)
          return false if body.nil?

          # Handle simple case: def authorize(...); true; end
          return true if body.type == :true # rubocop:disable Lint/BooleanSymbol

          # Handle multi-statement case: def authorize(...); puts "foo"; true; end
          if body.type == :begin
            last_statement = body.children.last
            return last_statement&.type == :true # rubocop:disable Lint/BooleanSymbol
          end

          false
        end
      end
    end
  end
end
