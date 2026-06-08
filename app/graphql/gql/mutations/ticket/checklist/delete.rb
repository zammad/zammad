# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::Checklist::Delete < Ticket::Checklist::Base
    description 'Delete a ticket checklist.'

    argument :checklist_id, GraphQL::Types::ID, required: true, loads: Gql::Types::ChecklistType, loads_pundit_method: :destroy?, description: 'ID of the ticket checklist to delete.'

    field :success, Boolean, description: 'Was the mutation succcessful?'

    def resolve(checklist:)
      checklist.destroy!

      {
        success: true,
      }
    end
  end
end
