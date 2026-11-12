# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Chat::Session::Typing < BaseMutation
    description 'Show the customer of a chat session the current agent runs that the agent is typing'

    argument :session_id, GraphQL::Types::ID, description: 'The chat session the agent is typing in'

    field :success, Boolean, description: 'Whether the customer was told'

    requires_permission 'chat.agent'
    requires_enabled_setting 'chat'

    def resolve(session_id:)
      session = Gql::ZammadSchema.verified_object_from_id(session_id, type: ::Chat::Session)

      { success: Service::Chat::Session::Typing.with_current_user(context.current_user).execute(session:) }
    end
  end
end
