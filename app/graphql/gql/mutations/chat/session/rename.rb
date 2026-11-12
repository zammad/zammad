# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Chat::Session::Rename < BaseMutation
    description 'Name a chat session the current agent runs or ran'

    argument :session_id, GraphQL::Types::ID, description: 'The chat session to name'
    argument :name, String, description: 'The name of the conversation; blank takes it away'

    field :session, Gql::Types::Chat::SessionType, description: 'The named chat session'

    requires_permission 'chat.agent'
    requires_enabled_setting 'chat'

    def resolve(session_id:, name:)
      session = Gql::ZammadSchema.verified_object_from_id(session_id, type: ::Chat::Session)

      { session: Service::Chat::Session::Rename.with_current_user(context.current_user).execute(session:, name:) }
    end
  end
end
