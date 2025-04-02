# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Checklist
  class TemplateType < Gql::Types::BaseObject
    include Gql::Types::Concerns::IsModelObject
    include Gql::Types::Concerns::HasPunditAuthorization

    description 'Checklist template'

    field :name, String
    field :active, Boolean
  end
end
