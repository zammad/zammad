# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require_relative 'concerns/can_check_gql_operation'

module RuboCop
  module Cop
    module Zammad
      class GraphqlAuthorizeDisallowed < Base
        include CanCheckGqlOperation

        MSG = 'GraphQL operations must not define an `self.authorize` method. Use helpers or authorized?'.freeze

        def on_defs(node)
          return if !inside_gql_operation?(node)
          return if node.method_name != :authorize

          add_offense(node.loc.name)
        end
      end
    end
  end
end
