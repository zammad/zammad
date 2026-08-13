# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Loaded via a plain 'require' (not Zeitwerk), so - unlike production - the extension files
#   are not reachable via autoload. Require them explicitly and install them under
#   'Extensions' before the possible_types(...) call below triggers '.extension_types'.
require_relative 'with_extensions_type/extensions/alpha_extension'
require_relative 'with_extensions_type/extensions/beta_extension'

module Gql::Types
  module BaseUnionSpec
    # Fixture union with an extensions directory, used by spec/graphql/gql/types/base_union_spec.rb.
    class WithExtensionsType < BaseUnion
      description 'Fixture union with extensions'

      module Extensions
        AlphaExtension = Gql::Types::BaseUnionSpec::AlphaExtensionSource
        BetaExtension  = Gql::Types::BaseUnionSpec::BetaExtensionSource
      end

      possible_types Gql::Types::TicketType, *extension_types
    end
  end
end
