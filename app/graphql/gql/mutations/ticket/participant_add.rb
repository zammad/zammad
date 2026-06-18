# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::ParticipantAdd < BaseMutation
    description 'Add a non-agent customer as participant to a ticket.'

    argument :ticket_id, GraphQL::Types::ID, loads: Gql::Types::TicketType, loads_pundit_method: :agent_update_access?, description: 'Ticket to add the participant to.'
    argument :user_id, GraphQL::Types::ID, loads: Gql::Types::UserType, description: 'User ID to add as participant.'

    field :participant, Gql::Types::UserType, null: true, description: 'The added participant, or null if the mutation failed.'

    requires_enabled_setting 'ticket_participants_enabled', error_message: __('The ticket participants feature is not active.')

    def resolve(ticket:, user:)
      if user.blank?
        return { participant: nil, errors: [user_error(__('User not found.'))] }
      end

      if user.permissions?('ticket.agent')
        return { participant: nil, errors: [user_error(__('Agents cannot be added as participants.'))] }
      end

      if user.id == ticket.customer_id
        return { participant: nil, errors: [user_error(__('The ticket customer is already a participant.'))] }
      end

      if ::Mention.subscribed?(ticket, user)
        return { participant: nil, errors: [user_error(__('This user is already a participant.'))] }
      end

      ::Mention.subscribe!(ticket, user)

      { participant: user }
    end

    private

    def user_error(message)
      { message: message }
    end
  end
end
