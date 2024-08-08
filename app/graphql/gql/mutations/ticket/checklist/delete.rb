# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::Checklist::Delete < BaseMutation
    description 'Delete a ticket checklist.'

    argument :checklist_id, GraphQL::Types::ID, required: true, loads: Gql::Types::ChecklistType, description: 'ID of the ticket checklist to delete.'

    field :success, Boolean, description: 'Was the mutation succcessful?'

    def resolve(checklist:)
      checklist.destroy!

      {
        success: true,
      }
    rescue => e
      error_response({ message: e.message })
    end

    def authorized?(checklist:, title: '')
      Pundit.authorize(context.current_user, checklist.ticket, :update?)
    end
  end
end
