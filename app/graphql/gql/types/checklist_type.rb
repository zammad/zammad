# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class ChecklistType < Gql::Types::BaseObject
    include Gql::Types::Concerns::IsModelObject

    description 'Ticket checklist'

    field :name, String
    field :completed, Boolean, method: :completed?, null: false
    field :incomplete, Integer, null: false
    field :items, [Gql::Types::Checklist::ItemType], method: :sorted_items, null: false
  end
end
