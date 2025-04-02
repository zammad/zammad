# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class TemplateType < Gql::Types::BaseObject
    include Gql::Types::Concerns::IsModelObject

    description 'Ticket template'

    field :name, String, null: false
    field :options, GraphQL::Types::JSON
    field :active, Boolean
  end
end
