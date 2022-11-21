# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class ObjectAttributeValueType < Gql::Types::BaseObject

    description 'Data of one object attribute value of another object'

    field :attribute, Gql::Types::ObjectManager::FrontendAttributeType, null: false, description: 'The object attribute record'
    field :value, GraphQL::Types::JSON, description: "The value of the current object's object attribute"

    field :rendered_value, GraphQL::Types::JSON, description: 'Rendered version of the value that considers templates which are defined' do
      argument :template_render_context, Gql::Types::Input::TemplateRenderContextInputType, description: 'Context data for the text module rendering, e.g. customer data.'
    end

    def rendered_value(template_render_context:)
      value = @object[:value]
      return value if !value.is_a?(String)

      template = @object.dig(:attribute, :data_option, 'linktemplate')
      return value if !template

      NotificationFactory::Renderer.new(
        objects:  template_render_context.to_context_hash,
        template: template,
        escape:   false
      ).render
    end
  end
end
