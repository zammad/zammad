# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  # Computed per agent by Service::Chat::AgentState; the topics the agent handles are
  #   the ones switched on in their chat preferences.
  class Chat::AgentStateType < Gql::Types::BaseObject
    description 'What the chat panel shows the current agent: the queues of their topics, the running sessions, the available agents and their own availability'

    field :active, Boolean, null: false, description: 'Whether the agent is available for chats'
    field :topics, [Gql::Types::Chat::TopicType, { null: false }], null: false, description: 'All active chat topics, for the agent to choose the ones they handle'
    field :waiting_queues, [Gql::Types::Chat::WaitingQueueType, { null: false }], null: false, description: 'The waiting customers of each topic the agent handles'
    field :running_sessions, [Gql::Types::Chat::SessionType, { null: false }], null: false, description: 'Sessions in progress in the topics the agent handles, with any agent, and those of the agent in other topics, oldest first'
    # Dependent like a belongs_to, so a chat agent without ticket permissions sees the names.
    field :available_agents, [Gql::Types::UserType, { null: false }], null: false, is_dependent_field: true, description: 'Agents currently available for the topics the agent handles'
    field :seats_available, Integer, null: false, description: 'Chats the available agents can still take, across the topics the agent handles'
    field :seats_total, Integer, null: false, description: 'Chats the available agents can hold at once, across the topics the agent handles'
  end
end
