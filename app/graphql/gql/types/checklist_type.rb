# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class ChecklistType < Gql::Types::BaseObject
    include Gql::Types::Concerns::IsModelObject
    include Gql::Types::Concerns::HasPunditAuthorization

    description 'Ticket checklist'

    belongs_to :ticket, Gql::Types::TicketType, null: false

    field :name,       String
    field :completed,  Boolean, method: :completed?, null: false
    field :incomplete, Integer, null: false
    field :complete,   Integer, null: false
    field :total,      Integer, null: false
    field :items,      [Gql::Types::Checklist::ItemType], method: :sorted_items, null: false
  end
end
