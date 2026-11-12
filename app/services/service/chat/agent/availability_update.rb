# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The new UI's counterpart of the legacy chat_agent_state event.
class Service::Chat::Agent::AvailabilityUpdate < Service::Base
  requires_current_user!

  attr_reader :active

  def initialize(active:)
    @active = active
  end

  def execute
    take_only_topic if active

    # The setter answers whether the flag changed, with the new row the first time; nothing to tell
    #   the others when it did not. The actor is named: their other windows have no reply channel.
    if ::Chat::Agent.state(current_user.id, active)
      ::Chat.broadcast_agent_state_update(::Chat.agent_active_chat_ids(current_user), agent_ids: [current_user.id])
    end

    active
  end

  private

  # Like the old UI, a single topic needs no choice: switching on takes it, with the greetings stored for it.
  def take_only_topic
    return if ::Chat.agent_active_chat_ids(current_user).any?

    topics = ::Chat.where(active: true).limit(2).to_a
    return if topics.size != 1

    ::Service::Chat::Preferences::Update
      .with_current_user(current_user)
      .execute(topics: [{ topic: topics.first, active: true }])

    # The update writes through its own instance of the user.
    current_user.reload
  end
end
