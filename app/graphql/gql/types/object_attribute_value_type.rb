# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class ObjectAttributeValueType < Gql::Types::BaseObject

    description 'Data of one object attribute value of another object'

    field :attribute, Gql::Types::ObjectManager::FrontendAttributeType, null: false, description: 'The object attribute record'
    field :value, GraphQL::Types::JSON, description: "The value of the current object's object attribute"
    field :rendered_value, GraphQL::Types::JSON, description: 'Rendered version of the value that considers templates which are defined'

    def rendered_value
      value = @object[:value]
      return value if !value.is_a?(String)

      template = @object.dig(:attribute, :data_option, 'linktemplate')
      return value if !template

      NotificationFactory::Renderer.new(
        objects:  { @object[:parent].class.name.downcase.to_sym => @object[:parent] },
        template: template,
        escape:   false
      ).render
    end
  end
end
