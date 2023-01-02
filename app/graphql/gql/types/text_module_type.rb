# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

# frozen_string_literal: true

module Gql::Types
  class TextModuleType < Gql::Types::BaseObject
    include Gql::Types::Concerns::IsModelObject
    include Gql::Types::Concerns::HasInternalNoteField
    include Gql::Types::Concerns::HasPunditAuthorization

    description 'Text modules'

    field :name, String, null: false
    field :keywords, String
    field :active, Boolean, null: false
    field :content, String

    field :rendered_content, String do
      argument :template_render_context, Gql::Types::Input::TemplateRenderContextInputType, description: 'Context data for the text module rendering, e.g. customer data.'
    end

    field :groups, Gql::Types::GroupType.connection_type

    def rendered_content(template_render_context:)
      NotificationFactory::Renderer.new(
        objects:  template_render_context.to_context_hash,
        template: @object.content,
        escape:   false
      ).render

    end
  end
end
