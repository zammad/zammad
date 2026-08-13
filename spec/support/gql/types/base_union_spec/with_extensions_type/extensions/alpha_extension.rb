# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Kept flat and namespace-independent (not nested under WithExtensionsType::Extensions via
#   'class'/'module' keywords): WithExtensionsType's own possible_types call now reads
#   '*extension_types' at class-body time, so under plain 'require' (no Zeitwerk in
#   spec/support) this file and its parent union would otherwise race to load first and
#   deadlock whichever loads second. with_extensions_type.rb installs this class under the
#   expected 'Extensions::AlphaExtension' constant instead.
module Gql::Types
  module BaseUnionSpec
    class AlphaExtensionSource
      def self.possible_types
        [Gql::Types::UserType]
      end
    end
  end
end
