# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require_relative 'concerns/can_check_gql_operation'

module RuboCop
  module Cop
    module Zammad
      class GraphqlAuthorizeRequiresPermission < Base
        include CanCheckGqlOperation
        extend AutoCorrector

        MSG = 'Replace `authorize` method with `requires_permission` when checking user permission.'.freeze

        def on_def(node)
          return if !inside_gql_operation?(node)
          return if node.method_name != :authorize

          handle_authorize_method(node)
        end

        def on_defs(node)
          return if !inside_gql_operation?(node)
          return if node.method_name != :authorize

          handle_authorize_method(node)
        end

        private

        def handle_authorize_method(node)
          permission_name = extract_permission(node)
          return if permission_name.nil?

          add_offense(node) do |corrector|
            corrector.replace(node, "requires_permission #{permission_name.source}")
          end
        end

        def extract_permission(method_node)
          body = method_node.body
          return nil if body.nil?
          return nil if !valid_permissions_call?(body)
          return nil if !valid_receiver_chain?(body)
          return nil if !valid_method_parameter?(body, method_node)

          arg = body.first_argument
          arg if arg&.str_type?
        end

        def valid_permissions_call?(body)
          body.send_type? && body.method_name == :permissions?
        end

        def valid_receiver_chain?(body)
          receiver = body.receiver
          return false if !receiver&.send_type?
          return false if receiver.method_name != :current_user

          param_receiver = receiver.receiver
          param_receiver&.send_type? == false && %i[lvar identifier].include?(param_receiver.type)
        end

        def valid_method_parameter?(body, method_node)
          param_receiver = body.receiver.receiver
          param_name = param_receiver.children.last
          method_params = method_node.arguments.map(&:name)

          method_params.include?(param_name)
        end
      end
    end
  end
end
