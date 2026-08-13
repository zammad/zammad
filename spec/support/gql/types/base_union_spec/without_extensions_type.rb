# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  module BaseUnionSpec
    # Fixture union without an extensions directory, used by spec/graphql/gql/types/base_union_spec.rb.
    class WithoutExtensionsType < BaseUnion
      description 'Fixture union without extensions'

      possible_types Gql::Types::TicketType
    end
  end
end
