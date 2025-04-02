# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::Checklist::Delete < Ticket::Checklist::Base
    description 'Delete a ticket checklist.'

    argument :checklist_id, GraphQL::Types::ID, required: true, loads: Gql::Types::ChecklistType, description: 'ID of the ticket checklist to delete.'

    field :success, Boolean, description: 'Was the mutation succcessful?'

    def authorized?(checklist:)
      pundit_authorized?(checklist, :destroy?)
    end

    def resolve(checklist:)
      checklist.destroy!

      {
        success: true,
      }
    end
  end
end
