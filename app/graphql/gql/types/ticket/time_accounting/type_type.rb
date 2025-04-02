# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Ticket::TimeAccounting
  class TypeType < Gql::Types::BaseObject
    include Gql::Types::Concerns::IsModelObject
    include Gql::Types::Concerns::HasInternalNoteField

    description 'Ticket time accounting activity types'

    field :name, String, null: false
    field :active, Boolean, null: false
  end
end
