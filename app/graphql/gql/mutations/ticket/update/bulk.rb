# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::Update::Bulk < BaseMutation
    include Gql::Mutations::Ticket::Concerns::HandlesGroup

    description 'Bulk-update tickets.'

    argument :ticket_ids, [GraphQL::Types::ID], loads: Gql::Types::TicketType, description: 'The tickets to be updated'
    argument :input, Gql::Types::Input::Ticket::UpdateInputType, description: 'The ticket data'
    argument :macro_id, GraphQL::Types::ID, loads: Gql::Types::MacroType, required: false, description: 'The macro to apply onto ticket'

    field :success, Boolean, description: 'Were the tickets updated successfully?'
    # Overwrite the default errors field.
    field :errors, [Gql::Types::Ticket::Update::BulkUserErrorType], description: 'Did the bulk update fail?'

    def self.authorize(_obj, ctx)
      ctx.current_user.permissions?(['ticket.agent'])
    end

    def authorized?(tickets:, input:, macro: nil)
      tickets.all? { |ticket| pundit_authorized?(ticket, :agent_update_access?) }
    end

    def resolve(tickets:, input:, macro: nil)
      return group_has_no_email_error if !group_has_email?(input: input)

      execute_transaction(tickets) do |ticket|
        Service::Ticket::Update
          .new(current_user: context.current_user)
          .execute(ticket: ticket, ticket_data: input, skip_validators: Service::Ticket::Update::Validator.exceptions, macro:)
      end
    end

    def execute_transaction(tickets, &)
      errors = nil

      ActiveRecord::Base.transaction do
        tickets.each(&)
      rescue => e
        raise e if !e.try(:record)

        errors = [ { failed_ticket: e.record, message: e.message, error_type: e.class.to_s } ]
        raise ActiveRecord::Rollback
      end

      errors ? { errors: } : { success: true }
    end
  end
end
