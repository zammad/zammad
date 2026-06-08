# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::Update::Bulk < BaseMutation
    include Gql::Mutations::Ticket::Concerns::HandlesGroup

    description 'Bulk-update tickets.'

    argument :selector, Gql::Types::Input::Ticket::Bulk::SelectorInputType, description: 'The selector for bulk ticket update.'
    argument :perform, Gql::Types::Input::Ticket::Bulk::PerformInputType, description: 'The bulk update action to be performed on the selected tickets.'

    field :async, Boolean, description: 'Whether the update is being processed asynchronously. This will be true if the number of tickets exceeds the defined threshold.'
    field :total, Integer, description: 'Total number of tickets selected for update.'

    field :failed_count, Integer, null: true, description: ''
    field :inaccessible_ticket_ids, [GraphQL::Types::ID], null: true, description: 'Tickets that are no longer accessible to the user.'
    field :invalid_ticket_ids, [GraphQL::Types::ID], null: true, description: 'Tickets that failed to update due to validation errors or other issues.'

    requires_permission 'ticket.agent'

    def resolve(selector:, perform:)
      return group_has_no_email_error if !group_has_email?(input: perform[:input])

      result = Service::Ticket::Bulk::DispatchUpdate
        .with_current_user(context.current_user)
        .execute(selector:, perform:)

      convert_to_global_ids(result)
    end

    private

    def convert_to_global_ids(result)
      %i[invalid_tickets inaccessible_tickets].each do |key|
        tickets = result.delete(key)
        next if !tickets

        result["#{key.to_s.singularize}_ids"] = tickets.map(&:to_gid)
      end

      result
    end
  end
end
