# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Loaded via a plain 'require' (not Zeitwerk), so - unlike production - the extension file
#   is not reachable via autoload. Require it explicitly and install it under 'Extensions'
#   before the possible_types(...) call below triggers '.extensions'.
require_relative 'with_model_extensions_type/extensions/organization_extension'

module Gql::Types
  module BaseUnionSpec
    # Fixture union mirroring SearchResult::ItemType's '.models' extension pattern
    #   (load-time possible_types derived from a frozen, memoized searchable_models list),
    #   used by spec/graphql/gql/types/base_union_spec.rb.
    class WithModelExtensionsType < BaseUnion
      description 'Fixture union with model-based extensions'

      BASE_MODELS = [::Ticket].freeze

      module Extensions
        OrganizationExtension = Gql::Types::BaseUnionSpec::OrganizationExtensionSource
      end

      def self.searchable_models
        @searchable_models ||= (BASE_MODELS + extensions.flat_map(&:models)).freeze
      end

      possible_types(*searchable_models.map { |model| "Gql::Types::#{model.name}Type".constantize })
    end
  end
end
