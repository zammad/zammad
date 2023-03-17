# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::ObjectManager
  class FrontendAttributeType < Gql::Types::BaseObject

    description 'An object manager attribute record especially for the frontend'

    field :name, String, null: false
    field :display, String, null: false, resolver_method: :resolve_display
    field :data_type, String, null: false
    field :data_option, GraphQL::Types::JSON
    field :screens, GraphQL::Types::JSON
    field :is_internal, Boolean, null: false

    # Custom resolvers are needed as there are conflicts with a built-in 'display' method.
    def resolve_display
      @object[:display]
    end
  end
end
