# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class TemplateType < Gql::Types::BaseObject
    include Gql::Types::Concerns::IsModelObject
    include Gql::Types::Concerns::HasPunditAuthorization

    description 'Ticket template'

    field :name, String, null: false
    field :options, GraphQL::Types::JSON
    field :active, Boolean
  end
end
