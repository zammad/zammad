# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class ChecklistType < Gql::Types::BaseObject
    include Gql::Types::Concerns::IsModelObject

    description 'Ticket checklist'

    field :name, String
    field :items, [Gql::Types::Checklist::ItemType], method: :sorted_items
    field :completed, Boolean, method: :completed?
  end
end
