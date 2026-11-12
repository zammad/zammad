# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Chat::Agent::Heartbeat < BaseMutation
    description 'Keep the current agent counted as present for chats; sent when the chat panel opens and then every 55 seconds'

    field :success, Boolean, null: false, description: 'Was the mutation successful?'

    requires_permission 'chat.agent'
    requires_enabled_setting 'chat'

    def resolve(...)
      {
        success: ::Service::Chat::Agent::Heartbeat.with_current_user(context.current_user).execute,
      }
    end
  end
end
