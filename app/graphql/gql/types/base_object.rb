# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class BaseObject < GraphQL::Schema::Object
    include Gql::Concerns::HandlesAuthorization
    include Gql::Concerns::HasNestedGraphqlName
    include Gql::Types::Concerns::HasModelRelations

    edge_type_class       Gql::Types::BaseEdge
    connection_type_class Gql::Types::BaseConnection
    field_class           Gql::Fields::BaseField

    description 'Base class for all GraphQL objects'

    # ALlow specifying a custom connection type class on any type.
    def self.custom_connection_type(type_class:, type_name:)
      initialize_relay_metadata
      @custom_connection_type ||= {}
      @custom_connection_type[type_name] ||= begin
        edge_type_class = edge_type
        Class.new(type_class) do
          graphql_name(type_name)
          edge_type(edge_type_class)
        end
      end
    end
  end
end
