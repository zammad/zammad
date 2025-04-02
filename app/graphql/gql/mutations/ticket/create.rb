# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::Create < BaseMutation
    include Gql::Mutations::Ticket::Concerns::HandlesGroup

    description 'Create a new ticket.'

    argument :input, Gql::Types::Input::Ticket::CreateInputType, description: 'The ticket data'

    field :ticket, Gql::Types::TicketType, description: 'The created ticket. If this is present but empty, the mutation was successful but the user has no rights to view the new ticket.'

    def self.authorize(_obj, ctx)
      ctx.current_user.permissions?(['ticket.agent', 'ticket.customer'])
    end

    def resolve(input:)
      return group_has_no_email_error if !group_has_email?(input: input)

      {
        ticket: Service::Ticket::Create
          .new(current_user: context.current_user)
          .execute(ticket_data: input)
      }
    rescue Exceptions::InvalidAttribute => e
      field = e.attribute == 'email_recipient' ? 'customer_id' : e.attribute

      error_response({ field:, message: e.message })
    end
  end
end
