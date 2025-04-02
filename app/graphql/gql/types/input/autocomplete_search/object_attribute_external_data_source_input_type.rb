# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::AutocompleteSearch
  class ObjectAttributeExternalDataSourceInputType < InputType

    description 'Input fields for object attribute external data source autocomplete searches.'

    argument :object, Gql::Types::Enum::ObjectManagerObjectsType, description: 'Object name of the object attribute, e.g. Ticket'
    argument :attribute_name, String, description: 'Name of the object attribute'
    argument :template_render_context, Gql::Types::Input::TemplateRenderContextInputType, description: 'Context data for the search url rendering, e.g. customer data.'
  end
end
