# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::ObjectManager
  class AttributeType < Gql::Types::BaseObject
    include Gql::Concern::IsModelObject

    description 'An object manager attribute record'

    # field :object_lookup_id, Integer, null: false
    field :name, String, null: false
    field :display, String, null: false, resolver_method: :resolve_display
    field :data_type, String, null: false
    field :data_option, GraphQL::Types::JSON, null: true
    # field :data_option_new, String, null: true
    field :editable, Boolean, null: false
    field :active, Boolean, null: false
    field :screens, GraphQL::Types::JSON, null: true
    # field :to_create, Boolean, null: false
    # field :to_migrate, Boolean, null: false
    # field :to_delete, Boolean, null: false
    # field :to_config, Boolean, null: false
    field :position, Integer, null: false

    # Custom resolver is needed as there is a conflict with a built-in 'display' method.
    def resolve_display
      @object.display
    end
  end
end
