# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Trigger GraphQL subscriptions for the events the legacy delivery sends to the participants.
module Chat::Session::TriggersSubscriptions
  extend ActiveSupport::Concern

  private

  # To everyone subscribed, the agent who caused the event included: their other windows have no
  #   reply channel, unlike the legacy client the message ignores. A transferred session keeps its agent.
  def trigger_subscriptions(message)
    return if user_id.blank? || state == 'waiting'

    payload = subscription_payload(message)
    return if payload.blank?

    Gql::Subscriptions::Chat::SessionUpdates.trigger(
      payload,
      arguments: { session_id: Gql::ZammadSchema.id_from_object(self) },
    )
  end

  def subscription_payload(message)
    data = message[:data]

    case message[:event]
    when 'chat_session_message'
      { message: data[:message] }
    when 'chat_session_typing'
      # Only the customer's typing is pushed: the agent's own typing goes to the customer, not to their other windows.
      { typing: true } if data[:user_id] != user_id
    when 'chat_session_notice'
      { notice: data[:message] }
    when 'chat_session_left'
      { left_by: data[:realname] }
    when 'chat_session_closed'
      { closed_by: data[:realname] }
    end
  end
end
