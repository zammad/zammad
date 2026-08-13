# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# This is required because of circular references in BaseEdge and BaseConnection.
# Both of them are BaseObject subclasses yet referenced by BaseObject.
# Works fine if BaseObject is loaded first though!
Gql::Types::BaseObject # rubocop:disable Lint/Void

module Gql::Types
  class BaseUnion < GraphQL::Schema::Union
    edge_type_class(Gql::Types::BaseEdge)
    connection_type_class(Gql::Types::BaseConnection)

    # default union type resolution
    def self.resolve_type(obj, _context)
      "Gql::Types::#{obj.class.name}Type".constantize
    end

    # Unions can be extended, e.g. by addons: extension classes placed in the
    #   union's '<union_file>/extensions/' directory are loaded automatically
    #   and provide additional entries via class methods (usually
    #   '.possible_types', see .extension_types).
    def self.extensions
      @extensions ||= begin
        extensions_path = "#{Object.const_source_location(name).first.delete_suffix('.rb')}/extensions"

        if Dir.exist?(extensions_path)
          namespace = "#{name}::Extensions"
          Mixin::RequiredSubPaths.eager_load_recursive(namespace, extensions_path)

          namespace.safe_constantize&.constants&.sort&.map { |extension| "#{namespace}::#{extension}".constantize } || []
        else
          []
        end
      end
    end

    # Additional possible types provided by extension classes (see .extensions).
    def self.extension_types
      extensions.flat_map(&:possible_types)
    end
  end
end
