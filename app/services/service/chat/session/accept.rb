# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The new UI's counterpart of the legacy chat_session_start event. The agent has no legacy client id,
#   so unlike there nobody is added as recipient of the session.
class Service::Chat::Session::Accept < Service::Base
  requires_current_user!

  # Leaves the window of the agent time to open and follow the session before the greeting arrives.
  GREETING_DELAY = 1.6.seconds

  attr_reader :topic

  # Without a topic, the topics the agent handles.
  def initialize(topic: nil)
    @topic = topic
  end

  def execute
    chat_session = ::Chat::Session.claim_next(chat_ids, current_user)

    raise Exceptions::UnprocessableContent, __('No session available.') if !chat_session

    chat_session.search_index_update_after_claim
    started = chat_session.send_start_to_customer

    ::Chat.broadcast_agent_state_update([chat_session.chat_id], agent_ids: [chat_session.user_id])
    ::Chat.broadcast_customer_state_update(chat_session.chat_id)

    greet(chat_session) if started

    chat_session
  end

  private

  def chat_ids
    topic ? [topic.id] : ::Chat.agent_active_chat_ids(current_user)
  end

  # Once per accepted session, however many windows the agent has open. The old UI greets from the browser,
  #   and a window of it that opens the session before the job has run still does.
  def greet(chat_session)
    phrase = greeting_phrase(chat_session.chat_id)
    return if !phrase

    ChatGreetingJob.set(wait: GREETING_DELAY).perform_later(chat_session.id, current_user.id, phrase)
  rescue => e
    # The session is claimed and the customer told already, a greeting that fails must not fail the accept.
    Rails.logger.error { "Greeting of chat session #{chat_session.id} failed (#{e.class.name}): #{e.message}" }
  end

  def greeting_phrase(chat_id)
    ::Chat.agent_phrases(current_user.preferences[:chat], chat_id).sample
  end
end
