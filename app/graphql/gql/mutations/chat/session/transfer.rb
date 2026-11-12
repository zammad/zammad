# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Chat::Session::Transfer < BaseMutation
    description 'Put a running chat session of the current agent back into the queue of another topic'

    argument :session_id, GraphQL::Types::ID, description: 'The chat session to transfer'
    argument :topic_id, GraphQL::Types::ID, description: 'The topic whose queue the customer moves to'

    field :session, Gql::Types::Chat::SessionType, description: 'The transferred chat session'

    requires_permission 'chat.agent'
    requires_enabled_setting 'chat'

    def resolve(session_id:, topic_id:)
      session = Gql::ZammadSchema.verified_object_from_id(session_id, type: ::Chat::Session)
      topic   = Gql::ZammadSchema.verified_object_from_id(topic_id, type: ::Chat)

      { session: Service::Chat::Session::Transfer.with_current_user(context.current_user).execute(session:, topic:) }
    end
  end
end
