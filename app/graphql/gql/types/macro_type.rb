# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class MacroType < Gql::Types::BaseObject
    include Gql::Types::Concerns::IsModelObject
    include Gql::Types::Concerns::HasInternalNoteField
    include Gql::Types::Concerns::HasPunditAuthorization

    description 'Returns a list of macros'

    field :name, String, null: false
    field :active, Boolean, null: false
    field :perform, String, null: false
    field :ux_flow_next_up, String, null: false
  end
end
