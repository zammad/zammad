# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Chat::Session::End < BaseMutation
    description 'Close a chat session the current agent runs'

    argument :session_id, GraphQL::Types::ID, description: 'The chat session to close'

    field :session, Gql::Types::Chat::SessionType, description: 'The closed chat session'

    requires_permission 'chat.agent'
    requires_enabled_setting 'chat'

    def resolve(session_id:)
      session = Gql::ZammadSchema.verified_object_from_id(session_id, type: ::Chat::Session)

      { session: Service::Chat::Session::End.with_current_user(context.current_user).execute(session:) }
    end
  end
end
