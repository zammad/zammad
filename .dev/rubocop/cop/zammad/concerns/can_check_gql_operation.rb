# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require_relative 'can_check_namespace'

module RuboCop
  module Cop
    module Zammad
      module CanCheckGqlOperation
        include CanCheckNamespace

        DISALLOW_IN = %w[Gql::Mutations Gql::Queries Gql::Subscriptions].freeze

        def inside_gql_operation?(node)
          inside_namespace?(node, *DISALLOW_IN)
        end
      end
    end
  end
end
