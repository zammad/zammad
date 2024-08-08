# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::Checklist::ItemUpsert < BaseMutation
    description 'Update or create a ticket checklist item.'

    argument :checklist_id, GraphQL::Types::ID, required: true, loads: Gql::Types::ChecklistType, description: 'ID of the ticket checklist to update or create an item for.'
    argument :checklist_item_id, GraphQL::Types::ID, required: false, loads: Gql::Types::Checklist::ItemType, description: 'ID of the ticket checklist item to update.'
    argument :input, Gql::Types::Input::Ticket::Checklist::ItemInputType, required: true, description: 'Input field values of the ticket checklist item.'

    field :success, Boolean, description: 'Was the mutation succcessful?'
    field :checklist_item_id, GraphQL::Types::ID, null: true, description: 'ID of the updated or created checklist item.'

    def resolve(checklist:, input:, checklist_item: nil)
      if checklist_item
        checklist_item.update!(**input)
      else
        checklist_item = checklist.items.create!(input.to_h)
      end

      {
        success:           true,
        checklist_item_id: Gql::ZammadSchema.id_from_object(checklist_item),
      }
    rescue => e
      error_response({ message: e.message })
    end

    def authorized?(checklist:, input:, checklist_item: nil)
      Pundit.authorize(context.current_user, checklist.ticket, :update?)
    end
  end
end
