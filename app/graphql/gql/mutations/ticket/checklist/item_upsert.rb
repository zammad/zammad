# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::Checklist::ItemUpsert < Ticket::Checklist::Base
    description 'Update or create a ticket checklist item.'

    argument :checklist_id, GraphQL::Types::ID, required: true, loads: Gql::Types::ChecklistType, description: 'ID of the ticket checklist to update or create an item for.'
    argument :checklist_item_id, GraphQL::Types::ID, required: false, loads: Gql::Types::Checklist::ItemType, description: 'ID of the ticket checklist item to update.'
    argument :input, Gql::Types::Input::Ticket::Checklist::ItemInputType, required: true, description: 'Input field values of the ticket checklist item.'

    field :checklist_item, Gql::Types::Checklist::ItemType, null: true, description: 'Updated or created checklist item.'

    def authorized?(checklist:, input:, checklist_item: nil)
      if checklist_item
        Pundit.authorize(context.current_user, checklist_item, :update?)
      end
      Pundit.authorize(context.current_user, Checklist::Item.new(checklist:), :create?)
    end

    def resolve(checklist:, input:, checklist_item: nil)
      if checklist_item
        checklist_item.update!(**input)
      else
        checklist_item = checklist.items.create!(input.to_h)
      end

      {
        checklist_item:
      }
    end
  end
end
