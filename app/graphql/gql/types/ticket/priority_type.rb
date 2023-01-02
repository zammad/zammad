# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Ticket
  class PriorityType < Gql::Types::BaseObject
    include Gql::Types::Concerns::IsModelObject
    include Gql::Types::Concerns::HasInternalNoteField

    description 'Ticket priorities'

    field :name, String, null: false
    field :default_create, Boolean, null: false
    field :ui_icon, String
    field :ui_color, String
    field :active, Boolean, null: false
  end
end
