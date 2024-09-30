# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::Checklist::ItemDelete < Ticket::Checklist::Base
    description 'Delete a ticket checklist item.'

    argument :checklist_id, GraphQL::Types::ID, required: true, loads: Gql::Types::ChecklistType, description: 'ID of the ticket checklist to delete an item in.'
    argument :checklist_item_id, GraphQL::Types::ID, required: true, loads: Gql::Types::Checklist::ItemType, description: 'ID of the ticket checklist item to delete.'

    field :success, Boolean, description: 'Was the mutation succcessful?'

    def authorized?(checklist:, checklist_item:)
      Pundit.authorize(context.current_user, checklist_item, :destroy?)
    end

    def resolve(checklist:, checklist_item:)
      raise ActiveRecord::RecordInvalid, __('The given checklist item does not belong to the given checklist.') if !checklist_item.checklist.eql?(checklist)

      checklist_item.destroy!

      {
        success: true,
      }
    end
  end
end
