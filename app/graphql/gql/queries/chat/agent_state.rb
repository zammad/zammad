# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Chat::AgentState < BaseQuery
    description 'Fetch what the chat panel shows the current agent: the queues of their topics, the running sessions, the available agents and their own availability'

    requires_permission 'chat.agent'
    requires_enabled_setting 'chat'

    type Gql::Types::Chat::AgentStateType, null: false

    def resolve(...)
      ::Service::Chat::AgentState
        .with_current_user(context.current_user)
        .execute
    end
  end
end
