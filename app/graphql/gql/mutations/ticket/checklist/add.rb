# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::Checklist::Add < BaseMutation
    description 'Create an empty checklist or a checklist based on a template for a ticket.'

    argument :ticket, Gql::Types::Input::Locator::TicketInputType, description: 'Ticket to create the new checklist for.'
    argument :template_id, GraphQL::Types::ID, required: false, description: 'Checklist template ID to base the ticket checklist on.'

    field :checklist, Gql::Types::ChecklistType, null: true, description: 'Created checklist'
    field :errors, [Gql::Types::UserErrorType], description: 'Errors encountered during execution of the mutation.'

    def resolve(ticket:, template_id: nil)
      checklist = if template_id
                    Gql::ZammadSchema.verified_object_from_id(template_id, type: ::ChecklistTemplate).create_from_template!(ticket_id: ticket.id)
                  else
                    ::Checklist.create!(name: '', ticket:)
                  end

      { checklist: }
    rescue ActiveRecord::RecordInvalid => e
      error_response({ message: e.message })
    end

    def authorized?(ticket:, template_id: nil)
      Pundit.authorize(context.current_user, ticket, :update?)
    end
  end
end
