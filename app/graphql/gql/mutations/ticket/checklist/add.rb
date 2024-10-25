# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::Checklist::Add < Ticket::Checklist::Base
    description 'Create an empty checklist or a checklist based on a template for a ticket.'

    argument :ticket_id, GraphQL::Types::ID, loads: Gql::Types::TicketType, description: 'Ticket to create the new checklist for.'
    argument :template_id, GraphQL::Types::ID, required: false, description: 'Checklist template ID to base the ticket checklist on.'

    field :checklist, Gql::Types::ChecklistType, null: true, description: 'Created checklist'

    def authorized?(ticket:, template_id: nil)
      Setting.get('checklist') && Pundit.authorize(context.current_user, ticket, :agent_update_access?)
    end

    def resolve(ticket:, template_id: nil)
      checklist = if template_id
                    template = Gql::ZammadSchema.verified_object_from_id(template_id, type: ::ChecklistTemplate)

                    Checklist.create_from_template!(ticket, template)
                  else
                    Checklist.create_fresh!(ticket)
                  end

      { checklist: }
    end
  end
end
