# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::Selector
  class ObjectInputType < Gql::Types::BaseInputObject

    description 'Per-object selector, pairing a searchable model with its selector conditions.'

    argument :object, Gql::Types::Enum::SearchableModelsType, description: 'Searchable model the selector applies to, e.g. Ticket'
    argument :selector, Gql::Types::Input::Selector::NodeInputType, description: 'Selector conditions to apply for the given object'
  end
end
