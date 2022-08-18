# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class ObjectAttributeValueType < Gql::Types::BaseObject

    description 'Data of one object attribute value of another object'

    field :attribute, Gql::Types::ObjectManager::FrontendAttributeType, null: false, description: 'The object attribute record'
    field :value, GraphQL::Types::JSON, null: true, description: "The value of the current object's object attribute"
  end
end
