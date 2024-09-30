# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::Checklist::ItemOrderUpdate < Ticket::Checklist::Base
    description 'Update order of the ticket checklist items.'

    argument :checklist_id, GraphQL::Types::ID, required: true, loads: Gql::Types::ChecklistType, description: 'ID of the ticket checklist to update the order for.'
    argument :order, [GraphQL::Types::ID], required: true, description: 'New order of the ticket checklist item IDs.'

    field :success, Boolean, description: 'Was the mutation succcessful?'

    def authorized?(checklist:, order:)
      Pundit.authorize(context.current_user, checklist, :update?)
    end

    def resolve(checklist:, order:)
      checklist.sorted_item_ids = []

      order.each do |id|
        checklist.sorted_item_ids << Gql::ZammadSchema.object_from_id(id).id
      end

      checklist.save!

      {
        success: true,
      }
    end
  end
end
