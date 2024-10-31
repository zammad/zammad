# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

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
  end
end
