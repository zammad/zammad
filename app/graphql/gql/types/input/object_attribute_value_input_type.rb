# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input
  class ObjectAttributeValueInputType < Gql::Types::BaseInputObject
    description 'Data of one object attribute value of another object'

    argument :name, String, required: true, description: "The name of the current object's attribute"
    argument :value, GraphQL::Types::JSON, required: false, description: "The value of the current object's object attribute"
  end
end
