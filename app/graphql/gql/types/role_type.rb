# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class RoleType < Gql::Types::BaseObject
    include Gql::Types::Concerns::IsModelObject
    include Gql::Types::Concerns::HasPunditAuthorization
    include Gql::Types::Concerns::HasInternalNoteField

    description 'Roles'

    field :name, String
  end
end
