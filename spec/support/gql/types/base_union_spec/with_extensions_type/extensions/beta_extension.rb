# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Kept flat and namespace-independent - see alpha_extension.rb for why.
module Gql::Types
  module BaseUnionSpec
    class BetaExtensionSource
      def self.possible_types
        [Gql::Types::OrganizationType]
      end
    end
  end
end
