# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class MentionType < BaseObject
    include Gql::Types::Concerns::HasDefaultModelFields
    include Gql::Types::Concerns::HasScopedModelUserRelations

    description 'Mention'

    # Only list mentions of active users by default.
    #   This can be disabled by using scope: false on a field definition.
    #   See https://graphql-ruby.org/authorization/scoping.html
    def self.scope_items(items, _ctx)
      items.joins(:user).where(user: { active: true })
    end

    belongs_to :user,        Gql::Types::UserType,   null: false
    belongs_to :mentionable, Gql::Types::TicketType, null: false

    field :user_ticket_access, Gql::Types::Policy::MentionUserTicketAccessType, null: false, method: :itself

    # True if this mention represents a non-agent participant (shown in the
    # participants sidebar). Agents get access via group permissions, not via
    # mentions, so agent mentions are excluded from the participant list.
    # Resolved backend-side so the frontend does not need to fetch user permissions
    # (which are only authorized for the current user).
    field :is_participant, Boolean, null: false

    def is_participant
      return false if @object.user.permissions?('ticket.agent')
      return false if !@object.user.active?
      return false if !@object.user.permissions?('ticket.customer')
      # The ticket's own customer is not a participant — they already have
      # customer access, and ParticipantAdd rejects adding them.
      return false if @object.mentionable.is_a?(Ticket) && @object.mentionable.customer_id == @object.user.id

      true
    end
  end
end
