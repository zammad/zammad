# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Checklist
  class ItemType < Gql::Types::BaseObject
    include Gql::Types::Concerns::IsModelObject

    description 'Ticket checklist item'

    field :text, String, null: false
    field :checked, Boolean, null: false
    field :ticket, Gql::Types::TicketType
    field :ticket_access, Gql::Types::Enum::ChecklistItemTicketAccessType

    def ticket
      ticket_reference!
    rescue
      nil
    end

    def ticket_access
      ticket_reference!

      'Granted'
    rescue Pundit::NotAuthorizedError
      'Forbidden'
    rescue
      nil
    end

    private

    def ticket_reference!
      ticket = object.ticket
      Pundit.authorize(context.current_user, ticket, :show?)

      ticket
    end
  end
end
