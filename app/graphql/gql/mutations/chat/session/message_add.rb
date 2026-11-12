# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Chat::Session::MessageAdd < BaseMutation
    description 'Write a message to the customer of a chat session the current agent runs'

    argument :session_id, GraphQL::Types::ID, description: 'The chat session to write to'
    argument :content, String, description: 'The message, as HTML'

    field :message, Gql::Types::Chat::MessageType, description: 'The written message'

    requires_permission 'chat.agent'
    requires_enabled_setting 'chat'

    def resolve(session_id:, content:)
      session = Gql::ZammadSchema.verified_object_from_id(session_id, type: ::Chat::Session)

      { message: Service::Chat::Session::MessageAdd.with_current_user(context.current_user).execute(session:, content:) }
    rescue Exceptions::UnprocessableContent => e
      error_response({ message: e.message })
    end
  end
end
