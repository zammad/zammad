# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Checklist
  class ItemType < Gql::Types::BaseObject
    include Gql::Types::Concerns::IsModelObject
    include Gql::Types::Concerns::HasPunditAuthorization

    description 'Ticket checklist item'

    belongs_to :checklist, Gql::Types::ChecklistType, null: false

    field :text, String, null: false
    field :checked, Boolean, null: false
    field :ticket_reference, Gql::Types::TicketReferenceType, method: :ticket
  end
end
