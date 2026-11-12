# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The new UI's counterpart of the legacy chat_transfer event, which lets any chat agent transfer any session.
class Service::Chat::Session::Transfer < Service::Base
  requires_current_user!

  attr_reader :session, :topic

  def initialize(session:, topic:)
    @session = session
    @topic   = topic
  end

  def execute
    previous_topic_id = nil

    # The check holds only under the lock: the customer or a job can close the session between its load and the write.
    session.with_lock do
      raise Exceptions::Forbidden, __('You are not running this chat session.') if !session.running_for?(current_user)

      previous_topic_id = session.chat_id

      # The session keeps its agent, like in the legacy event: it counts against their seats until someone accepts it.
      session.update!(chat_id: topic.id, state: 'waiting')
    end

    ::Chat.broadcast_agent_state_update([previous_topic_id, topic.id], agent_ids: [session.user_id])

    session.send_to_recipients(
      event: 'chat_session_notice',
      data:  {
        session_id: session.session_id,
        message:    __('Conversation is transferred into another chat. Please stay tuned.'),
      },
    )

    session
  end
end
