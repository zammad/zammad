# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::ParticipantRemove < BaseMutation
    description 'Remove a participant from a ticket.'

    argument :ticket_id, GraphQL::Types::ID, loads: Gql::Types::TicketType, loads_pundit_method: :agent_update_access?, description: 'Ticket to remove the participant from.'
    argument :user_id, GraphQL::Types::ID, loads: Gql::Types::UserType, description: 'User ID to remove as participant.'

    field :success, Boolean, description: 'Was the mutation successful?'

    requires_enabled_setting 'ticket_participants_enabled', error_message: __('The ticket participants feature is not active.')

    def resolve(ticket:, user:)
      if user.blank?
        return { success: false }
      end

      # NOTE: Erreichbar nur für Agenten. Das Load-Gate `loads_pundit_method:
      # :agent_update_access?` blockt Nicht-Agenten VOR resolve. Dieser Zweig ist
      # daher Agent-Self-Remove, NICHT Customer-Self-Remove. Customer-Self-Remove
      # gehört zu NEU-26 (gleicher show?/Policy-Knoten wie Self-Add). Nicht
      # 'aktivieren' durch UI-Bau, ohne vorher den Policy-Pfad zu lösen.
      if user.id != context.current_user.id && !context.current_user.permissions?('ticket.agent')
        return { success: false }
      end

      ::Mention.unsubscribe!(ticket, user)

      { success: true }
    end
  end
end
