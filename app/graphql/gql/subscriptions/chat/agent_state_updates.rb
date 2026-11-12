# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class Chat::AgentStateUpdates < BaseSubscription
    description 'Updates to what the chat panel shows the current agent'

    subscription_scope :current_user_id

    requires_permission 'chat.agent'
    requires_enabled_setting 'chat'

    field :agent_state, Gql::Types::Chat::AgentStateType, null: true, description: 'The current state, resolved like the chatAgentState query'

    # Without a payload: the state is recomputed for each subscriber, who may handle other topics
    #   than the agent whose action caused it.
    def self.trigger_for(user)
      trigger(nil, scope: user.id)
    end

    # Recomputed for the subscriber rather than derived from the event, so the payload can
    #   replace the query result as a whole.
    def update
      { agent_state: ::Service::Chat::AgentState.with_current_user(context.current_user).execute }
    end
  end
end
