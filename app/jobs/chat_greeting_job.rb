# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Greets the customer for the agent who accepted the chat, unless the conversation went on without it.
class ChatGreetingJob < ApplicationJob
  def perform(chat_session_id, agent_id, phrase)
    chat_session = Chat::Session.find_by(id: chat_session_id)
    agent        = User.find_by(id: agent_id)

    return if !chat_session || !agent

    greet(chat_session, agent, phrase)
  end

  private

  def greet(chat_session, agent, phrase)
    # Another job or a message of the agent may be on its way, which the check has to see once it is done.
    chat_session.with_lock do
      next if !chat_session.running_for?(agent)
      next if chat_session.conversation_underway?

      Service::Chat::Session::MessageAdd
        .with_current_user(agent)
        .execute(session: chat_session, content: phrase.text2html)
    end
  end
end
