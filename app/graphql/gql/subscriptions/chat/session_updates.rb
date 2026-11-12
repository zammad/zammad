# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class Chat::SessionUpdates < BaseSubscription
    description 'What happens in a chat session'

    requires_permission 'chat.agent'
    requires_enabled_setting 'chat'

    argument :session_id, GraphQL::Types::ID, description: 'Chat session identifier'

    field :message, Gql::Types::Chat::MessageType, null: true, description: 'A message was added to the conversation'
    field :typing, GraphQL::Types::Boolean, null: true, description: 'The customer is typing'
    field :notice, String, null: true, description: 'Notice about what the customer does, like the page they moved to'
    field :left_by, String, null: true, description: 'Name shown with the notice that the customer left the conversation'
    field :closed_by, String, null: true, description: 'Name shown with the notice that the conversation was closed'

    def subscribe(session_id:)
      Gql::ZammadSchema.authorized_object_from_id(session_id, type: ::Chat::Session, user: context.current_user, query: :subscribe?)

      {}
    end

    def update(session_id:)
      object
    end
  end
end
