# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class ObjectAttributeValueType < Gql::Types::BaseObject

    description 'Data of one object attribute value of another object'

    field :attribute, Gql::Types::ObjectManager::FrontendAttributeType, null: false, description: 'The object attribute record'
    field :value, GraphQL::Types::JSON, description: "The value of the current object's object attribute"
    field :rendered_link, String, description: 'Rendered version of link, if attribute has defined template'

    def rendered_link
      template = @object.dig(:attribute, :data_option, 'linktemplate')
      return nil if !template

      NotificationFactory::Renderer.new(
        objects:  { @object[:parent].class.name.downcase.to_sym => @object[:parent] },
        template: template,
        escape:   false
      ).render
    end
  end
end
