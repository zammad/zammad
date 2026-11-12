# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Chat::Session < BaseQuery
    description 'Fetch a chat session with its conversation'

    argument :session_id, GraphQL::Types::ID, description: 'The chat session'

    requires_permission 'chat.agent'
    requires_enabled_setting 'chat'

    type Gql::Types::Chat::SessionType, null: false

    def resolve(session_id:)
      Gql::ZammadSchema.authorized_object_from_id(session_id, type: ::Chat::Session, user: context.current_user, query: :read_conversation?)
    end
  end
end
