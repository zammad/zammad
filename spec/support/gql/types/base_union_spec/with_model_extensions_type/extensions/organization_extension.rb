# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Kept flat and namespace-independent (not nested under WithModelExtensionsType::Extensions
#   via 'class'/'module' keywords): under plain 'require' (spec/support has no Zeitwerk
#   autoloading), this file and its parent union race to load first, and the union's own
#   class body calls '.extensions' synchronously (mirroring SearchResult::ItemType). Nesting
#   here would deadlock whichever file loads second. with_model_extensions_type.rb installs
#   this class under the expected 'Extensions::OrganizationExtension' constant instead.
module Gql::Types
  module BaseUnionSpec
    class OrganizationExtensionSource
      def self.models
        [::Organization]
      end
    end
  end
end
