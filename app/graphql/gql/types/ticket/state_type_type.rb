# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Ticket
  class StateTypeType < Gql::Types::BaseObject
    include Gql::Types::Concerns::IsModelObject
    include Gql::Types::Concerns::HasInternalNoteField

    description 'Ticket state types'

    field :name, String, null: false
  end
end
