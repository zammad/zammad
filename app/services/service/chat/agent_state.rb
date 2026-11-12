# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# What Chat.agent_state tells the old UI, as records instead of attribute hashes and legacy assets.
class Service::Chat::AgentState < Service::Base
  requires_current_user!

  def execute
    {
      active:           ::Chat::Agent.state(current_user.id),
      topics:           ::Chat.where(active: true).reorder(:name),
      waiting_queues:   waiting_queues,
      running_sessions: running_sessions,
      available_agents: available_agents,
      seats_available:  seats_total - ::Chat.active_chat_count(chat_ids),
      seats_total:      seats_total,
    }
  end

  private

  def chat_ids
    @chat_ids ||= ::Chat.agent_active_chat_ids(current_user)
  end

  # One pass over the agents, looked up one by one: the service runs for every subscriber whenever a chat changes.
  def seats_by_agent
    @seats_by_agent ||= ::Chat.available_agents_with_concurrent(chat_ids)
  end

  def available_agents
    ::User.where(id: seats_by_agent.keys).to_a
  end

  def seats_total
    seats_by_agent.values.sum
  end

  # The agent's own sessions stay with them when they stop handling their topic, like in the old UI.
  def running_sessions
    running = ::Chat::Session.where(state: 'running')

    running.where(chat_id: chat_ids).or(running.where(user_id: current_user.id)).reorder(created_at: :asc)
  end

  def waiting_queues
    ::Chat.where(active: true, id: chat_ids).reorder(:name).map do |topic|
      {
        topic:    topic,
        sessions: ::Chat::Session.where(state: 'waiting', chat_id: topic.id).reorder(created_at: :asc),
      }
    end
  end
end
