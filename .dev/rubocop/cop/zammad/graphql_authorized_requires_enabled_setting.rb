# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require_relative 'concerns/can_check_gql_operation'

module RuboCop
  module Cop
    module Zammad
      class GraphqlAuthorizedRequiresEnabledSetting < Base
        include CanCheckGqlOperation
        extend AutoCorrector

        MSG = 'Replace `authorized?` method with `requires_enabled_setting` when checking Setting.get.'.freeze

        def on_def(node)
          return if !inside_gql_operation?(node)
          return if node.method_name != :authorized?

          handle_authorized_method(node)
        end

        def on_defs(node)
          return if !inside_gql_operation?(node)
          return if node.method_name != :authorized?

          handle_authorized_method(node)
        end

        private

        def handle_authorized_method(node)
          setting_names = collect_setting_names(node.body)
          return if setting_names.empty?
          return if other_calls?(node.body)

          add_offense(node) do |corrector|
            replacement = setting_names
              .map { |name| "requires_enabled_setting #{name.source}" }
              .join("\n#{' ' * node.loc.column}")

            corrector.replace(node, replacement)
          end
        end

        def collect_setting_names(body)
          return [] if body.nil?

          setting_names = []

          traverse_nodes(body) do |node|
            next if !node.send_type?
            next if node.method_name != :get
            next if !node.receiver&.const_type?

            # Get the constant name - for `Setting`, it's the last child
            const_name = node.receiver.children.last
            next if const_name != :Setting

            arg = node.first_argument
            setting_names << arg if arg&.str_type?
          end

          setting_names
        end

        def other_calls?(body)
          return false if body.nil?

          has_other = false

          traverse_nodes(body) do |node|
            # Allow Setting.get calls
            if node.send_type? && node.method_name == :get &&
               node.receiver&.const_type? && node.receiver.children.last == :Setting
              next
            end

            # Allow super
            next if node.zsuper_type?

            # If we see any other send node, it's an additional method call
            if node.send_type?
              has_other = true
              break
            end
          end

          has_other
        end

        def traverse_nodes(node, &)
          yield node if node.is_a?(RuboCop::AST::Node)

          node.children.each do |child|
            traverse_nodes(child, &) if child.is_a?(RuboCop::AST::Node)
          end
        end
      end
    end
  end
end
